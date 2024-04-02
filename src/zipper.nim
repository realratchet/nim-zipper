import std/[macros, strutils, enumerate]

proc collectIters(itIdents: openArray[NimNode]): NimNode {.compileTime.} =
    let nNextIterTuple = newNimNode(nnkTupleConstr)

    for nId in itIdents:
        nNextIterTuple.add(newCall(nId))

    return nNextIterTuple

proc createResultStatement(itIdents: openArray[NimNode]): NimNode {.compileTime.} =
    let nNextIter = newNimNode(nnkVarSection)
    let nNextIterDefs = newNimNode(nnkIdentDefs).add(newIdentNode("results"), newEmptyNode())

    nNextIterDefs.add(collectIters(itIdents))
    nNextIter.add(nNextIterDefs)

    return nNextIter

proc collectFinished(itIdents: openArray[NimNode]): NimNode {.compileTime.} =
    var nLastElement = newCall(bindSym("finished"), itIdents[0])

    for i in 1..<itIdents.len:
        let nOther = newCall(bindSym("finished"), itIdents[i])

        nLastElement = infix(nLastElement, "or", nOther)

    return nLastElement

proc createFinishedStatement(itIdents: openArray[NimNode]): NimNode {.compileTime.} =
    let nNextIter = newNimNode(nnkVarSection)
    let nNextIterDefs = newNimNode(nnkIdentDefs).add(newIdentNode("finished"), newEmptyNode())

    nNextIterDefs.add(collectFinished(itIdents))
    nNextIter.add(nNextIterDefs)

    return nNextIter

proc createWhileLoop(itIdents: openArray[NimNode]): NimNode {.compileTime.} =
    let nIdRes = newIdentNode("results")
    let nIdFinished = newIdentNode("finished")
    let nWhileStmt = newNimNode(nnkWhileStmt)
    let nNotFinished = prefix(nIdFinished, "not")
    let nStmtList = newNimNode(nnkStmtList)
    let nYieldStmt = newNimNode(nnkYieldStmt).add(nIdRes)

    nWhileStmt.add(nNotFinished)
    nWhileStmt.add(nStmtList)
    nStmtList.add(nYieldStmt)
    nStmtList.add(newNimNode(nnkAsgn).add(nIdRes, collectIters(itIdents)))
    nStmtList.add(newNimNode(nnkAsgn).add(nIdFinished, collectFinished(itIdents)))

    return nWhileStmt

proc rewriteAsIterator(nIterable: NimNode): NimNode {.compileTime.} =
    let nBody = newNimNode(nnkStmtList).add(
            newNimNode(nnkForStmt).add(
                newIdentNode("it"),
                nIterable,
                newNimNode(nnkStmtList).add(
                    newNimNode(nnkYieldStmt).add(newIdentNode("it")))
        )
    )

    let nProc = newProc(newEmptyNode(), [newIdentNode("auto")], nBody, nnkIteratorDef)

    return nProc

proc getIterator(nIterable: NimNode, nInIter: NimNode): NimNode {.compileTime.} =

    let nIterType = newIdentNode("auto")
    let nIdentDef = newNimNode(nnkIdentDefs)
    let nIteratorTy = newNimNode(nnkIteratorTy)
    let nIteratorPars = newNimNode(nnkFormalParams)

    nIteratorPars.add(nIterType)
    nIteratorTy.add(nIteratorPars, newEmptyNode())
    nIdentDef.add(nInIter, nIteratorTy, newEmptyNode())

    return nIterable

proc collectZipperArgs(nSqs: NimNode): (seq[NimNode], seq[NimNode], seq[NimNode]) {.compileTime.} =
    expectKind(nSqs, nnkBracket)

    var itProcArgs = @[newIdentNode("auto")]
    var itAssignments = newSeq[NimNode]()
    var itIdents = newSeq[NimNode]()

    for (i, nSq) in enumerate(nSqs):
        let nIterProcType = getType(nSq)

        let iterableType = $nIterProcType[0]

        expectKind(nIterProcType, nnkBracketExpr)

        let nIdent = genSym(nskVar, "it")
        let nIdentSq = (
            case iterableType.toLower:
            of "proc": getIterator(nSq, nIdent)
            of "seq", "array":
                rewriteAsIterator(nSq)
            else: raise newException(ValueError, "unsupported iterable")
        )

        let nAssignment = newNimNode(nnkVarSection).add(
                newNimNode(nnkIdentDefs).add(
                    nIdent, newEmptyNode(), nIdentSq
            )
        )

        itAssignments.add(nAssignment)
        itIdents.add(nIdent)

    return (itProcArgs, itAssignments, itIdents)

macro zipper*(nSqs: varargs[typed]): untyped =
    expectKind(nSqs, nnkBracket)
    expectMinLen(nSqs, 1)

    let (itProcArgs, itAssignments, itIdents) = collectZipperArgs(nSqs)
    let nBody = newNimNode(nnkStmtList)

    for nAssignment in itAssignments:
        nBody.add(nAssignment)

    nBody.add(createResultStatement(itIdents))
    nBody.add(createFinishedStatement(itIdents))
    nBody.add(createWhileLoop(itIdents))

    let nProcName = newEmptyNode()
    let nProc = newProc(nProcName, itProcArgs, nBody, nnkIteratorDef)

    nProc.addPragma(newIdentNode("closure"))

    return newCall(newPar(nProc))
