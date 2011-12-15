/*
    Copyright (c) 2002-2011 Tampere University of Technology.

    This file is part of TTA-Based Codesign Environment (TCE).

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the "Software"),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
    THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
    DEALINGS IN THE SOFTWARE.
 */
/**
 * @file BUBasicBlockScheduler.hh
 *
 * Declaration of BUBasicBlockScheduler class.
 *
 * @author Vladimir Guzma 2011 (vladimir.guzma-no.spam-tut.fi)
 * @note rating: red
 */

#ifndef TTA_BU_BB_SCHEDULER_HH
#define TTA_BU_BB_SCHEDULER_HH

#include "BUMoveNodeSelector.hh"
#include "DDGPass.hh"
#include "BasicBlockPass.hh"
#include "BasicBlockScheduler.hh"
#include "DataDependenceGraph.hh"

class BasicBlockNode;
class SimpleResourceManager;
class SoftwareBypasser;
class CopyingDelaySlotFiller;
class DataDependenceGraphBuilder;
class RegisterRenamer;
class MoveNode;
class MoveNodeGroup;
class LLVMTCECmdLineOptions;

/**
 * A class that implements the functionality of a bottom up basic block 
 * scheduler.
 *
 * Schedules the program one basic block at a time. Does not fill delay slots
 * if they couldn't be filled with the basic block's contents itself (no
 * instruction importing).
 */
class BUBasicBlockScheduler :
    public BasicBlockScheduler {
public:
    BUBasicBlockScheduler(
        InterPassData& data, SoftwareBypasser* bypasser=NULL, 
        CopyingDelaySlotFiller* delaySlotFiller=NULL,
        RegisterRenamer* registerRenamer = NULL);
    virtual ~BUBasicBlockScheduler();

    virtual void handleDDG(
        DataDependenceGraph& ddg,
        SimpleResourceManager& rm,
        const TTAMachine::Machine& targetMachine)
        throw (Exception);

    virtual std::string shortDescription() const;
    virtual std::string longDescription() const;

    virtual MoveNodeSelector* createSelector( 
        TTAProgram::BasicBlock& bb, const TTAMachine::Machine& machine) {
        return new BUMoveNodeSelector(bb, machine);
    }

    using BasicBlockPass::ddgBuilder;

private:
    void scheduleRRMove(MoveNode& moveNode)
        throw (Exception);

    void scheduleOperation(MoveNodeGroup& moves)
        throw (Exception);

    bool scheduleOperandWrites(MoveNodeGroup& moves, int cycle)
        throw (Exception);

    int scheduleResultReads(MoveNodeGroup& moves, int cycle)
        throw (Exception);

    void scheduleMove(MoveNode& move, int cycle)
        throw (Exception);

    void scheduleResultReadTempMoves(
        MoveNode& resultMove, MoveNode& resultRead, int lastUse)
        throw (Exception);

    void scheduleInputOperandTempMoves(
        MoveNode& resultMove, MoveNode& resultRead)
        throw (Exception);

    void scheduleRRTempMoves(
        MoveNode& regToRegMove, MoveNode& firstMove, int lastUse)
        throw (Exception);
        
    MoveNode* precedingTempMove(MoveNode& current);        
            
    unsigned int endCycle_;
};

#endif
