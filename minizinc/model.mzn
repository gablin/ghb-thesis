%
%  Main authors:
%    Gabriel Hjort Blindell <ghb@kth.se>
%    Mats Carlsson <matsc@sics.se>
%
%  Contributing authors:
%    Roberto Castaneda Lozano <rcas@sics.se>
%
%  Copyright (c) 2012-2018, Gabriel Hjort Blindell <ghb@kth.se>
%  All rights reserved.
%
%  Redistribution and use in source and binary forms, with or without
%  modification, are permitted provided that the following conditions are
%  met:
%  1. Redistributions of source code must retain the above copyright notice,
%     this list of conditions and the following disclaimer.
%  2. Redistributions in binary form must reproduce the above copyright
%     notice, this list of conditions and the following disclaimer in the
%     documentation and/or other materials provided with the distribution.
%  3. Neither the name of the copyright holder nor the names of its
%     contributors may be used to endorse or promote products derived from
%     this software without specific prior written permission.
%
%  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
%  IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
%  THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
%  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE LIABLE
%  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
%  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
%  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
%  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
%  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
%  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
%  THE POSSIBILITY OF SUCH DAMAGE.




%=====================
% EXTERNAL PARAMETERS
%=====================

% Function data.
int: numOperationsInFunction;
int: numDataInFunction;
int: numBlocksInFunction;
int: entryBlockOfFunction;
int: execFrequencyGCD;
array[allBlocksInFunction] of set of int: domSetsOfBlocksInFunction;
array[allOperationsInFunction] of set of int: depsOfOpsInFunction; % NOT IN
                                                                   % USE
array[allDataInFunction] of set of int: depsOfDataInFunction; % NOT IN USE
set of allOperationsInFunction: copiesInFunction;
set of allOperationsInFunction: controlOpsInFunction;
set of allDataInFunction: statesInFunction;
array[int, int] of int: defEdgesInFunction;
array[allBlocksInFunction] of int: execFrequencyOfBlockInFunction;
array[int] of set of int: interchangeableDataInFunction;
set of allDataInFunction: dataInFunctionUsedAtLeastOnce; % NOT IN USE

% Target machine data.
int: numLocations;
set of int: canonicalDataLocs;

% Match data.
int: numMatches;
int: numOperands;
array[allOperands] of set of int: operandAlternatives;
array[allMatches] of set of int: operationsCoveredByMatch;
array[allMatches] of set of int: operandsDefinedByMatch;
array[allMatches] of set of int: operandsUsedByMatch;
array[allMatches] of set of int: operandsExteriorToMatch;
array[allMatches] of set of int: operandsIntermediateToMatch;
array[allMatches] of set of int: entryBlockOfMatch;
array[allMatches] of set of int: spannedBlocksInMatch;
array[allMatches] of set of int: consumedBlocksInMatch;
array[int, int] of int: validDataLocsInMatch;

array[int, int] of int: inputDefEdgesInMatch;
array[int, int] of int: outputDefEdgesInMatch;
array[allMatches] of int: codeSizeOfMatch;
array[allMatches] of int: latencyOfMatch;
set of allMatches: copyInstrMatches;
set of allMatches: killInstrMatches;
set of allMatches: nullInstrMatches;
set of allMatches: phiInstrMatches;
array[allMatches] of allMatches: allMatchesBySize;

int: costLowerBound;
int: costUpperBound;

% Arrays that encode constraints
array[int, int] of int: validDataLocsInFunction;
array[int, int] of int: validDataLocRangesInFunction;
array[int, int] of int: sameDataLocsInFunction;
array[int, int] of int: validDataLocRangesInMatch;
array[int, int] of int: sameDataLocsInMatch;
array[int, int] of int: fallThroughBlockOfMatch;
array[int] of set of int: illegalMatchCombinations;

% These variables will be set by concatenating the definitions to the end of
% this file.


%=====================
% INTERNAL PARAMETERS
%=====================

% Total number of location values. Two additional values will be needed for
% representing the intermediate value location (for when the datum cannot be
% reused by other matches) and the killed location (for when the datum is
% defined by a kill match).
int: numLocValues = numLocations + 2;

% Reference to to the intermediate value location.
int: locValueForInt = numLocValues - 1;

% Reference to to the killed location.
int: locValueForKilled = numLocValues;

% Total number of data values. An additional value will be needed for
% representing the null datum (for operands used in non-selected matches).
int: numDataValues = numDataInFunction + 1;

% Reference to to the null datum.
int: datumValueForNull = numDataValues;

% Total number of blocks values. An additional value will be needed for
% representing the null block (to which non-selected matches will be
% placed).
int: numBlockValues = numBlocksInFunction + 1;

% Reference to the null block.
int: blockValueForNull = numBlockValues;

% Sets to be used as array ranges.
set of int: allOperationsInFunction = 1..numOperationsInFunction;
set of int: allDataInFunction = 1..numDataInFunction;
set of int: allBlocksInFunction = 1..numBlocksInFunction;
set of int: allMatches = 1..numMatches;
set of int: allOperands = 1..numOperands;
set of int: allLocValues = { x | x in canonicalDataLocs
                                      ++ [ locValueForInt
                                         , locValueForKilled
                                         ]
                           };

% The 'domRelMatrix' matrix is a 2D matrix with 2 columns:
%    col 1: a block i
%        2: a block j that dominates i
% In other words, domRelMatrix has a row [i, j] if and only if j belongs to
% domSetsOfBlocksInFunction[i].
%
% $\eqFormat{\refEquation{dominance-matrix}}$ in dissertation
int: numDomMatrixRows =
  sum (b in allBlocksInFunction)
  ( card(domSetsOfBlocksInFunction[b]) );
array[1..numDomMatrixRows, 1..2] of allBlocksInFunction: domRelMatrix =
  array2d( 1..numDomMatrixRows
         , 1..2
         , [ if k = 1 then i else j endif
           | i in allBlocksInFunction
           , j in domSetsOfBlocksInFunction[i]
           , k in 1..2
           ]
         );

% The set of matches that can cover a particular operation.
array[allOperationsInFunction] of set of allMatches: matchsetOfOp =
  [ { m | m in allMatches where op in operationsCoveredByMatch[m] }
  | op in allOperationsInFunction
  ];

% The set of matches that can define a particular datum.
array[allDataInFunction] of set of allMatches: defsetOfDatum =
  [ { m | m in allMatches
        , p in operandsDefinedByMatch[m]
          where d in operandAlternatives[p]
    }
  | d in allDataInFunction
  ];

% The set of matches that can define a particular datum and does not cover
% any operations.
array[int] of set of allMatches: defsetOfDatumOnly =
  [ M | M in defsetOfDatum
        where forall (i in index_set(matchsetOfOp))
              ( matchsetOfOp[i] != M )
  ];

% Maps a match to an operation. This is only needed for figuring out in
% which block a selected match is to be placed.
array[allMatches] of int: opOfM =
  [ min({ o | o in allOperationsInFunction where m in matchsetOfOp[o] })
  | m in allMatches
  ];

% Maps an operand to a match. This is only needed for figuring out which
% operands have not been assigned a datum.
array[allOperands] of int: matchOfP =
  [ m | p in allOperands
      , m in allMatches
        where p in operandsDefinedByMatch[m] union operandsUsedByMatch[m]
  ];

% The total cost is computed as:
%
%   sum (m in allMatches)
%   ( latencyOfMatch[m] * execFrequencyOfBlocks[place[m]] )
%
% but this implementation yields poor propagation. To improve propagation,
% we use the cost per operation instead of cost per selected match.
%
% First, we split the cost incurred by selecting a given match over the
% operations that it covers. As the latency of a match times the exeqution
% frequency of a given block may not be evenly divisible by the number of
% operations covered, some operations may have a greater cost than
% others. Then, we multiply each operation cost with the execution
% frequency of the block wherein the operation may be placed.
%
% This information is put in a matrix called 'costPerOpMatrix'.

% The 'costPerOpMatrix' is a 2D matrix with 4 columns:
%    col 1: an operation o
%        2: a match m that covers o
%        3: a block b in which m can be placed
%        4: the cost incurred by o if m is selected and placed in b
% For simplicity, we first create a list and then the matrix using the list.
%
% $\eqFormat{\refEquationList{div-mul-op-cost-function, div-mul-cost-matrix}}$ in dissertation
array[int] of int: costPerOpList =
  [ if      k = 1 then o
    else if k = 2 then m
    else if k = 3 then b
    else let
         { int: d = card(operationsCoveredByMatch[m])
         , int: q = latencyOfMatch[m] div d
         , int: r = latencyOfMatch[m] mod d
         } in if operationsCoveredByMatch[m][r+1] > o
              then (q+1) * execFrequencyOfBlockInFunction[b]
              else q * execFrequencyOfBlockInFunction[b]
              endif
    endif
    endif
    endif
  | o in allOperationsInFunction
  , m in allMatches
  , b in if card(entryBlockOfMatch[m]) > 0 then entryBlockOfMatch[m]
         else allBlocksInFunction
         endif
  , k in 1..4
    where o in operationsCoveredByMatch[m]
  ];
int: numCostPerOpMatrixRows = card(index_set(costPerOpList)) div 4;
array[1..numCostPerOpMatrixRows, 1..4] of int: costPerOpMatrix =
  array2d(1..numCostPerOpMatrixRows, 1..4, costPerOpList);

% A set with all the possible costs that can be incurred by any operation.
set of int: allOpCosts = { costPerOpMatrix[i, 4]
                         | i in 1..numCostPerOpMatrixRows
                         };

% The set of all non-phi instruction use operands.
set of int: nonPhiUseOperands =
  { p
  | m in allMatches diff phiInstrMatches
  , p in operandsUsedByMatch[m]
  };

% The set of operands which are either used or defined by kill instructions.
set of int: killOperands =
  array_union( [ operandsDefinedByMatch[m] | m in killInstrMatches ]
               ++
               [ operandsUsedByMatch[m] | m in killInstrMatches ]
             );


%===========
% VARIABLES
%===========

% Match selection.
array[allMatches] of var bool: sel;

% Blocks wherein the data are placed.
array[allDataInFunction] of var allBlocksInFunction: dplace;

% The block in which a particular operation is placed.
array[allOperationsInFunction] of var allBlocksInFunction: oplace;

% Data locations.
array[allDataInFunction] of var allLocValues: loc;

% Data selected for the operands.
array[allOperands] of var allDataInFunction: alt;

% Block ordering (succ[b] is the block appearing immeditely after block b
% in the generated code).
array[allBlocksInFunction] of var allBlocksInFunction: succ;

% Cost.
var int: totalcost;
array[allOperationsInFunction] of var allOpCosts: opcosts;


%================
% DUAL VARIABLES
%================

% The match that covers a particular operation.
array[allOperationsInFunction] of var allMatches: omatch;

% The match that defines a particular datum.
array[allDataInFunction] of var allMatches: dmatch;

% For selected, non-null, non-phi instruction use operands:
%   block where the datum of a given operand is used.
% For non-selected, non-null, non-phi instruction use operands:
%   block where the datum of a given operand is defined.
% For other operands:
%   1.
array[allOperands] of var allBlocksInFunction: uplace;


%====================
% GLOBAL CONSTRAINTS
%====================

include "globals.mzn";


%===========
% FUNCTIONS
%===========

% Bypasses the alt[.] variable if the given operand only has one
% alternative. Valid under the assumption that its match was selected.
var allDataInFunction: Alt(allOperands: p) =
  let { allDataInFunction: d = min(operandAlternatives[p]) }
  in if card(operandAlternatives[p]) = 1 then d else alt[p] endif;

% True if the value of a given operand for sure must not be in the
% intermediate value nor in the killed location.
test valueOfOpMustBeAvailable(allOperands: p) =
  exists (i in index_set_1of2(validDataLocRangesInMatch))
  ( validDataLocRangesInMatch[i, 2] = p /\
    validDataLocRangesInMatch[i, 4] < locValueForInt
    % Since locValueForInt < locValueForKilled, this also entails that the
    % range does not include locValueForKilled
  );

% True if a datum for sure must not be in the intermediate value nor in the
% killed location.
test valueMustBeAvailable(allDataInFunction: d) =
  forall ( m in defsetOfDatum[d] )
  ( not (m in killInstrMatches) /\
    exists ( use2 in operandsDefinedByMatch[m] intersect
                     operandsExteriorToMatch[m]
           )
    ( operandAlternatives[use2] = {d} )
  );


%==================
% BASE CONSTRAINTS
%==================

% Constrain locations of data representing values.
constraint
  forall (d in allDataInFunction)
  ( let { set of int: locs = { validDataLocsInFunction[i, 2]
                             | i in index_set_1of2(validDataLocsInFunction)
                               where validDataLocsInFunction[i, 1] = d
                             }
        }
    in if card(locs) > 0 then loc[d] in locs else true endif
  );

% Constrain locations of data that must be within a specific range.
constraint
  forall (i in index_set_1of2(validDataLocRangesInFunction))
  ( let { int: d = validDataLocRangesInFunction[i, 1]
        , int: l = validDataLocRangesInFunction[i, 2]
        , int: u = validDataLocRangesInFunction[i, 3]
        }
    in loc[d] in l..u
  );

% Constrain locations of data which must be assigned the same location.
constraint
  forall (i in index_set_1of2(sameDataLocsInFunction)) (
    let { int: p1 = sameDataLocsInFunction[i, 1]
        , int: p2 = sameDataLocsInFunction[i, 2]
        }
    in loc[Alt(p1)] = loc[Alt(p2)]
  );

% Constrain alternatives of operands.
constraint
  forall (p in allOperands)
  ( alt[p] in operandAlternatives[p] );

% All operands exterior to a match (excluding kill matches), and which are
% not states, must not be located in the intermediate value location nor
% the killed location.
constraint
  forall ( m in allMatches diff killInstrMatches
         , p in operandsExteriorToMatch[m]
           where not (operandAlternatives[p] subset statesInFunction)
              /\ not valueOfOpMustBeAvailable(p)
         )
  ( if forall (d in operandAlternatives[p])
       ( valueMustBeAvailable(d) )
    then true
    else sel[m] -> ( loc[Alt(p)] != locValueForInt /\
                     loc[Alt(p)] != locValueForKilled
                   )
    endif
  );

% All operands intermediate to a match must be located in the intermediate
% value location.
constraint
  forall ( m in allMatches
         , p in operandsIntermediateToMatch[m]
           where not (operandAlternatives[p] subset statesInFunction)
         )
  ( sel[m] -> loc[Alt(p)] = locValueForInt );

% If a match representing a phi instruction is selected, then its operands
% must be placed in the same location.
%
% $\eqFormat{\refEquation{phi-match-locations-alt}}$ in dissertation
constraint
  forall ( m in phiInstrMatches
         , p1 in operandsExteriorToMatch[m]
         )
  ( let { int: p2 = min(operandsExteriorToMatch[m]) }
    in if p1 != p2 then sel[m] -> loc[Alt(p1)] = loc[Alt(p2)]
       else true
       endif
  );

% Constrain locations of operands representing values for selected matches.
%
% $\eqFormat{\refEquation{compatible-locations-alt}}$ in dissertation
constraint
  forall ( m in allMatches
         , p in operandsDefinedByMatch[m] union operandsUsedByMatch[m]
         )
  ( let { set of int: locs = { validDataLocsInMatch[i, 3]
                             | i in index_set_1of2(validDataLocsInMatch)
                               where validDataLocsInMatch[i, 1] = m
                                     /\
                                     validDataLocsInMatch[i, 2] = p
                             }
        }
    in if card(locs) > 0
       then sel[m] -> loc[Alt(p)] in locs
       else true
       endif
  );

% Constrain locations of operands that must be within a specific range.
%
% If no entry appears in validDataLocRangesInMatch for a given match and
% operand, then it means no location restrictions are applied.
constraint
  forall (i in index_set_1of2(validDataLocRangesInMatch)) (
    let { int: m = validDataLocRangesInMatch[i, 1]
        , int: p = validDataLocRangesInMatch[i, 2]
        , int: l = validDataLocRangesInMatch[i, 3]
        , int: u = validDataLocRangesInMatch[i, 4]
        }
    in sel[m] -> loc[Alt(p)] in l..u
  );

% For selected matches that require two or more of its operands to have the
% same location, enforce them to be the same.
%
% Eq 1.16 in dissertation
constraint
  forall (i in index_set_1of2(sameDataLocsInMatch)) (
    let { int: m = sameDataLocsInMatch[i, 1]
        , int: p1 = sameDataLocsInMatch[i, 2]
        , int: p2 = sameDataLocsInMatch[i, 3]
        }
    in sel[m] -> loc[Alt(p1)] = loc[Alt(p2)]
  );

% If a match representing a phi instruction is selected, then its data must
% be defined in the blocks indicated by the definition edges.
%
% $\eqFormat{\refEquation{match-def-edges}}$ in dissertation
constraint
  forall (i in index_set_1of2(inputDefEdgesInMatch)) (
    let { int: m = inputDefEdgesInMatch[i, 1]
        , int: b = inputDefEdgesInMatch[i, 2]
        , int: p = inputDefEdgesInMatch[i, 3]
        }
    in sel[m] -> dplace[Alt(p)] = b
  );
constraint
  forall (i in index_set_1of2(outputDefEdgesInMatch)) (
    let { int: m = outputDefEdgesInMatch[i, 1]
        , int: b = outputDefEdgesInMatch[i, 2]
        , int: p = outputDefEdgesInMatch[i, 3]
        }
    in sel[m] -> dplace[Alt(p)] = b
  );

% A datum with a definition edge must be defined in the block of that edge.
%
% $\eqFormat{\refEquation{def-edges}}$ in dissertation
constraint
  forall (i in index_set_1of2(defEdgesInFunction)) (
    let { int: b = defEdgesInFunction[i, 1]
        , int: d = defEdgesInFunction[i, 2]
        }
    in dplace[d] = b
  );

% If a match is selected, then all operations covered by that match must be
% placed in the same block.
%
% $\eqFormat{\refEquation{operation-placement}}$ in dissertation
constraint
  forall ( m in allMatches
         , o in operationsCoveredByMatch[m]
           where o != opOfM[m]
         )
  ( sel[m] -> oplace[opOfM[m]] = oplace[o] );

% If a selected match m has an entry block b, then all operations covered
% by m must be placed in b.
%
% If a match has no entry block, then this set will be empty and hence there
% will be no such constraint. It is assumed that there will be at most one
% entry.
%
% $\eqFormat{\refEquation{preventing-control-flow-op-moves}}$ in dissertation
constraint
  forall ( m in allMatches
         , b in entryBlockOfMatch[m]
         , o in operationsCoveredByMatch[m]
         )
  ( sel[m] -> oplace[o] = b );

% Data defined by a selected match m must be defined either in one of the
% blocks spanned by m, or the block wherein the operations covered by m are
% placed.
%
% $\eqFormat{\refEquation{spanning-alt}}$ in dissertation
constraint
  forall ( m in allMatches
         , p in operandsDefinedByMatch[m]
         )
  ( sel[m] -> if card(spannedBlocksInMatch[m]) > 0
              then dplace[Alt(p)] in spannedBlocksInMatch[m]
              else forall (o in operationsCoveredByMatch[m])
                   ( dplace[Alt(p)] = oplace[o] )
              endif
  );

% No operations may be placed in a block which is consumed by some selected
% match.
%
% $\eqFormat{\refEquation{consumption}}$ in dissertation
constraint
  forall ( m in allMatches
         , o in allOperationsInFunction diff operationsCoveredByMatch[m]
         , b in consumedBlocksInMatch[m]
         )
  ( sel[m] -> oplace[o] != b );

% For each selected match m that apply fall-through, enforce either:
%    - that the fall-through block of m is the immediate successor of the
%      entry block of m, or
%    - that the fall-through block of m is one block away from the entry
%      block of m and the block in between contains no
%      non-null-instructions.
%
% $\eqFormat{\refEquationRange{block-order}{no-fall-through-to-fun-entry}}$ in dissertation
constraint
  forall (i in index_set_1of2(fallThroughBlockOfMatch))
  ( let { int: m = fallThroughBlockOfMatch[i, 1]
        , int: fall_b = fallThroughBlockOfMatch[i, 2]
        }
    in sel[m] -> falls_through(m, fall_b)
  );

predicate falls_through(allMatches: m, allBlocksInFunction: fall_b) =
  let { int: entry_b = min(entryBlockOfMatch[m])
      , var int: succ_b = succ[entry_b]
      }
  in succ_b != entryBlockOfFunction /\
     ( succ_b = fall_b \/
       ( succ[succ_b] = fall_b /\
         forall (o in allOperationsInFunction)
         ( oplace[o] != succ_b \/
           omatch[o] in nullInstrMatches
         )
       )
     );

% Enforce that, for each operation o, exactly one match must be selected
% such that o is covered.
%
% THIS HAS BEEN REPLACED WITH DUAL VARIABLE CONSTRAINT.

% Enforce that every datum is defined in a block such that the block
% dominates all blocks wherein the datum is used. This constraint shall not
% be applied to the generic phi patterns, nor to null instructions.
%
% This used to be enforced by the following constraint:
%
%   constraint
%     forall ( m in allMatches
%            , p in operandsUsedByMatch[m]
%              where not (m in phiInstrMatches)
%            )
%     ( dplace[alt[p]] in domSetsOfBlocksInFunction[place[m]] );
%
% but it has been reformulated using table constraints to avoid the use of
% set variables.
%
% This assumes that matches which use some data cover at least one
% operation, which should always hold.
%
% $\eqFormat{\refEquation{refined-dom}}$ in dissertation
constraint
  forall (p in nonPhiUseOperands)
  ( table([uplace[p], dplace[Alt(p)]], domRelMatrix) );

% $\eqFormat{\refEquation{refined-dom-selected}}$ in dissertation
constraint
  forall ( m in allMatches diff phiInstrMatches
         , p in operandsUsedByMatch[m]
         , o in operationsCoveredByMatch[m]
         )
  ( sel[m] -> oplace[o] = uplace[p] );

% $\eqFormat{\refEquation{refined-dom-not-selected}}$ in dissertation
constraint
  forall ( m in allMatches diff phiInstrMatches
         , p in operandsUsedByMatch[m]
         )
  ( not sel[m] -> uplace[p] = dplace[Alt(p)] );

% $\eqFormat{\refEquation{refined-dom-phi-operands}}$ in dissertation
constraint
  forall (p in allOperands diff nonPhiUseOperands)
  ( uplace[p] = 1 );

% A kill match is selected if and only if the location of the defined datum
% is in the killed location.
%
% $\eqFormat{\refEquation{killed-data}}$ in dissertation
constraint
  forall ( m in killInstrMatches
         , p in operandsDefinedByMatch[m]
         )
  ( sel[m] <-> loc[Alt(p)] = locValueForKilled );

% Ensure that succ forms a circuit (thus resulting in an ordering of
% blocks).
%
% $\eqFormat{\refEquation{block-order}}$ in dissertation
constraint
  if card(allBlocksInFunction) > 1
  then circuit(succ) :: domain
  else true
  endif;

% Forbid matches in an illegal combination from all being selected.
%
% $\eqFormat{\refEquation{cyclic-data-deps}}$ in dissertation
constraint
  forall (c in illegalMatchCombinations)
  ( sum (m in c) (bool2int(sel[m])) < card(c) );

% Constrain the cost that can be incurred by each operation.
%
% $\eqFormat{\refEquation{omatch-oplace-ocost-connection}}$ in dissertation
constraint
  forall (o in allOperationsInFunction)
  ( table([o, omatch[o], oplace[o], opcosts[o]], costPerOpMatrix) );

% The total cost is the sum of the costs incurred by all operations.
%
% $\eqFormat{\refEquation{total-cost}}$ in dissertation
constraint
  totalcost = sum(opcosts);

% Constraint the lower bound of the cost.
%
% $\eqFormat{\refEquation{cost-bounds}}$ in dissertation
constraint
  if costLowerBound > 0
  then totalcost >= costLowerBound
  else true
  endif;

% Constraint the upper bound of the cost (retrieved from LLVM).
%
% $\eqFormat{\refEquation{cost-bounds}}$ in dissertation
constraint
  if costUpperBound > 0
  then totalcost < costUpperBound
  else true
  endif;


%===========================
% DUAL VARIABLE CONSTRAINTS
%===========================

% For each operation o, exactly one match must be selected such that o is
% covered.
%
% This replaces the constraint that, for each operation o, exactly one match
% must be selected such that o is covered:
%
%   constraint
%     forall (o in allOperationsInFunction)
%     ( let { set of int: mset = { m
%                                | m in allMatches
%                                  where o in operationsCoveredByMatch[m]
%                                }
%           }
%       in sum (m in mset) (bool2int(sel[m])) = 1
%     );
%
% $\eqFormat{\refEquation{operation-coverage}}$ in dissertation
constraint
  forall (o in allOperationsInFunction)
  ( omatch[o] in matchsetOfOp[o]
    /\
    forall (m in matchsetOfOp[o])
    ( omatch[o] = m <-> sel[m] )
  );

% For each datum d, exactly one match must be selected such that d is
% defined.
%
% This replaces the constraint that that, for each datum d, exactly one
% match must be selected such that d is defined:
%
%   constraint
%     forall (d in allDataInFunction)
%     ( let { set of int: mset = { m | m in allMatches
%                                    , p in operandsDefinedByMatch[m]
%                                      where d in operandAlternatives[p]
%                                }
%           }
%       in sum (m in mset) (bool2int(sel[m])) = 1
%     );
%
% This is an implied constraint, but it also enforces that the patterns for
% defining the function input and constants are selected. Such patterns do
% not cover any operations, they are not entailed in the above constraint
% for exactly covering each operation.
%
% $\eqFormat{\refEquation{data-definitions}}$ in dissertation
constraint
  forall (d in allDataInFunction)
  ( dmatch[d] in defsetOfDatum[d]
    /\
    forall (m in defsetOfDatum[d])
    ( dmatch[d] = m <-> sel[m] )
  );


%=======================
% DOMINANCE CONSTRAINTS
%=======================

% Constrain the loc value for all data that are states.
%
% $\eqFormat{\refEquation{dom-cons-locs-of-states}}$ in dissertation
constraint
  forall (d in statesInFunction)
  ( loc[d] = locValueForInt );

% Fix operand value if match was not selected.
%
% $\eqFormat{\refEquation{dom-cons-operands-of-non-selected-matches}}$ in dissertation
constraint
  forall ( m in allMatches
         , p in operandsDefinedByMatch[m] union operandsUsedByMatch[m]
           where card(operandAlternatives[p]) > 1
         )
  ( not sel[m] -> alt[p] = min(operandAlternatives[p]) );

% Break symmetries introduced by interchangeable data.
%
% This could remove potential optimal solutions in situations where data is
% interchangeable WITHIN a group of matches, but not BETWEEN groups of
% matches. Have yet to see such an occurrance, though.
%
% $\eqFormat{\refEquation{dom-cons-interch-data-chains}}$ in dissertation
constraint
  forall ( chain in interchangeableDataInFunction )
  ( let { set of int: xset = { p | p in nonPhiUseOperands
                                   where operandAlternatives[p] = chain
                             }
        }
    in if card(xset) > 1
       then value_precede_chain(chain, [alt[p] | p in xset])
       else true
       endif
  );

% A consequence of symmetry breaking (concerns selection of null copies).
%
% $\eqFormat{\refEquationList{dom-cons-null-copy-match-selection, increasing-function}}$ in dissertation
constraint
  forall ( chain in interchangeableDataInFunction
           where forall (d in chain)
                 ( defsetOfDatum[d] subset copyInstrMatches )
         )
  ( let { array[int] of int: copies =
            [ min( defsetOfDatum[d] intersect
                   nullInstrMatches diff
                   killInstrMatches
                 )
            | d in chain
              where card( defsetOfDatum[d] intersect
                          nullInstrMatches diff
                          killInstrMatches
                        ) > 0
            ]
        }
    in increasing (m in copies)
       ( sel[m] )
  );

% A consequence of symmetry breaking (concerns selection of kill matches).
%
% $\eqFormat{\refEquation{dom-cons-kill-match-selection}}$ in dissertation
constraint
  forall ( chain in interchangeableDataInFunction
           where forall (d in chain)
                 ( defsetOfDatum[d] subset copyInstrMatches )
         )
  ( let { array[int] of int: kills =
            [ min(defsetOfDatum[d] intersect killInstrMatches)
            | d in chain
              where card(defsetOfDatum[d] intersect killInstrMatches) > 0
            ]
        }
  in if length(kills) > 0
     then increasing (m in kills)
          ( sel[m] )
     else true
     endif
  );


%=====================
% IMPLIED CONSTRAINTS
%=====================

% If all matches covering an operation o are not phi instruction, do not
% span any blocks, use datum du, and define datum dd, then the block
% defining du must dominate the block defining dd, and o must be placed in
% the block defining dd.
%
% $\eqFormat{\refEquationList{impl-cons-defs-dominate-defs, data-of-function}}$ in dissertation
constraint
  forall ( o in allOperationsInFunction
           where forall (m in matchsetOfOp[o])
                 ( not (m in phiInstrMatches) /\
                   card(spannedBlocksInMatch[m]) = 0
                 )
         )
  ( let { set of allMatches: M = matchsetOfOp[o]
        , int: mo = min({ m1 | m1 in M
                               where forall (m2 in M)
                                     ( card(operationsCoveredByMatch[m1]) <=
                                       card(operationsCoveredByMatch[m2])
                                     )
                        })
        , set of allDataInFunction: DD =
            { d | p in operandsDefinedByMatch[mo]
                , d in operandAlternatives[p]
            }
        , set of allDataInFunction: DU = { d | p in operandsUsedByMatch[mo]
                                             , d in operandAlternatives[p]
                                         }
        }
    in forall (dd in DD, du in DU)
       ( if forall (m in M)
            ( exists (p in operandsDefinedByMatch[m])
              ( operandAlternatives[p] = {dd} )
              /\
              exists (p in operandsUsedByMatch[m])
              ( operandAlternatives[p] = {du} )
            )
         then table([dplace[dd], dplace[du]], domRelMatrix) /\
              oplace[o] = dplace[dd]
         else true
         endif
       )
  );

% If all matches in the matchset covering a particular operation have
% identical entry blocks, and use datum d, then the block defining d must
% dominate the entry block.
%
% $\eqFormat{\refEquation{impl-cons-defs-dominate-entry-blocks}}$ in dissertation
constraint
  forall ( M in matchsetOfOp
         , d in allDataInFunction
           where forall (m in M)
                 ( not (m in phiInstrMatches)
                   /\
                   card(spannedBlocksInMatch[m]) > 0
                 )
         )
  ( let { int: Entry = min(entryBlockOfMatch[min(M)]) }
    in if forall (m in M)
          ( min(entryBlockOfMatch[m]) = Entry /\
            exists (p in operandsUsedByMatch[m])
            ( operandAlternatives[p] = {d} )
          )
       then table([Entry, dplace[d]], domRelMatrix)
       else true
       endif
  );

% If all matches in the matchset that cover a particular operation have
% identical spanned blocks, and define datum d, then d must be placed in a
% spanned block.
%
% $\eqFormat{\refEquation{impl-cons-defs-in-spanned-blocks}}$ in dissertation
constraint
  forall ( M in matchsetOfOp
         , d in allDataInFunction,
           where forall (m in M)
                 ( card(spannedBlocksInMatch[m]) > 0 )
         )
  ( let { set of int: Spanned = spannedBlocksInMatch[min(M)] }
    in if forall (m in M)
          ( spannedBlocksInMatch[m] = Spanned /\
            exists (p in operandsDefinedByMatch[m])
            ( operandAlternatives[p] = {d} )
          )
       then dplace[d] in Spanned
       else true
       endif
  );

% If all matches for an operation o have identical entry blocks, then o
% must be placed in the entry block.
%
% $\eqFormat{\refEquation{impl-cons-identical-entry-blocks}}$ in dissertation
constraint
  forall ( o in allOperationsInFunction
           where forall (m in matchsetOfOp[o])
                 ( card(spannedBlocksInMatch[m]) > 0 )
         )
  ( let { int: Entry = min(entryBlockOfMatch[min(matchsetOfOp[o])]) }
    in if forall (m in matchsetOfOp[o])
          ( min(entryBlockOfMatch[m]) = Entry )
       then oplace[o] = Entry
       else true
       endif
  );

% If all matches covering an operation o are all phi instructions and define
% the same datum, then o must be placed in the same block as the datum.
%
% $\eqFormat{\refEquation{impl-cons-place-phi-ops-same-as-def-edges}}$ in dissertation
constraint
  forall (i in index_set_1of2(defEdgesInFunction)) (
    let { int: b = defEdgesInFunction[i, 1]
        , int: d = defEdgesInFunction[i, 2]
        }
    in if defsetOfDatum[d] subset phiInstrMatches
       then forall (o in operationsCoveredByMatch[min(defsetOfDatum[d])])
            ( oplace[o] = b )
       else true
       endif
  );

% If for any two given blocks p and q, and fallThroughBlockOfMatch contains
% [_, p, q] but does not contain [_, p, q'] or [_, p', q], then succ[p] = q
% can only help, never hurt.
%
% $\eqFormat{\refEquation{impl-cons-fix-fall-throughs}}$ in dissertation
constraint
  let { array[allBlocksInFunction] of set of allBlocksInFunction: fwd =
          array1d( allBlocksInFunction
                 , [ { s | i in index_set_1of2(fallThroughBlockOfMatch)
                         , m in {fallThroughBlockOfMatch[i, 1]}
                         , s in {fallThroughBlockOfMatch[i, 2]}
                           where entryBlockOfMatch[m] = {b}
                     }
                   | b in allBlocksInFunction
                   ]
                 )
      , array[allBlocksInFunction] of set of allBlocksInFunction: bwd =
          array1d( allBlocksInFunction
                 , [ { s | i in index_set_1of2(fallThroughBlockOfMatch)
                         , m in {fallThroughBlockOfMatch[i, 1]}
                         , s in entryBlockOfMatch[m]
                           where fallThroughBlockOfMatch[i, 2] = b
                     }
                   | b in allBlocksInFunction
                   ]
                 )
      }
  in forall ( p in allBlocksInFunction
            , q in allBlocksInFunction
            )
     ( if fwd[p] = {q} /\ bwd[q] = {p}
       then succ[p] = q
       else true
       endif
     );

% For non-phi matches, no spanned blocks:
% if selected, blocks of used and defined data must be equal.
%
% $\eqFormat{\refEquationRange{impl-cons-no-span-uses}{impl-cons-no-span-use-defs}}$ in dissertation
constraint
  forall ( m in allMatches diff phiInstrMatches
           where card(spannedBlocksInMatch[m]) = 0
         )
  ( let { array[int] of int: uses = [p | p in operandsUsedByMatch[m]]
        , array[int] of int: defs = [p | p in operandsDefinedByMatch[m]]
        }
    in forall ( i in index_set(uses)
              , j in index_set(uses)
                where i < j
              )
       ( sel[m] -> uplace[uses[i]] = uplace[uses[j]] )
       /\
       forall ( i in index_set(defs)
              , j in index_set(defs)
                where i < j
              )
       ( sel[m] -> dplace[Alt(defs[i])] = dplace[Alt(defs[j])] )
       /\
       forall ( i in index_set(uses)
              , j in index_set(defs)
              )
       ( sel[m] -> uplace[uses[i]] = dplace[Alt(defs[j])] )
  );

% For non-phi matches, spanned blocks:
% if selected, blocks of use of inputs must be all equal.
%
% $\eqFormat{\refEquation{impl-cons-spanned-input}}$ in dissertation
constraint
  forall ( m in allMatches diff phiInstrMatches
           where card(spannedBlocksInMatch[m]) > 0
         )
  ( let { array[int] of int: use = [ p | p in operandsUsedByMatch[m]
                                              diff
                                              operandsDefinedByMatch[m]
                                   ]
        }
    in forall ( i in index_set(use)
              , j in index_set(use)
                where i < j
              )
       ( sel[m] -> uplace[use[i]] = uplace[use[j]] )
  );

% [MC 2]
%
% If all matches in the matchset covering a particular operation uses some
% datum d as input, then d cannot be placed in the intermediate value nor
% killed location.
%
% $\eqFormat{\refEquation{impl-cons-used-data-must-be-available}}$ in dissertation
constraint
  forall ( M in matchsetOfOp )
  ( let { int: mo = min(M)
        , set of int: uses1 = operandsUsedByMatch[mo] diff
                              operandsDefinedByMatch[mo]
        }
    in forall (use1 in uses1)
       ( let { set of int: data1 = operandAlternatives[use1] }
         in if forall (d in data1)
               ( not (d in statesInFunction) )
               /\
               forall ( m in M where m != mo )
               ( exists ( use2 in operandsUsedByMatch[m] diff
                                  operandsDefinedByMatch[m]
                        )
                 ( operandAlternatives[use2] = data1 )
               )
               /\
               forall (d in data1)
               ( not valueMustBeAvailable(d) )
            then exists (d in data1)
                 ( loc[d] != locValueForInt /\ loc[d] != locValueForKilled )
            else true
            endif
       )
  );

% If all matches in the matchset that defines a non-state datum d, are
% active, and define it in an exterior operand, then d must not be placed
% in the intermediate value nor killed location.
%
% This constraint does not dominate [MC 2], nor vice versa.
%
% $\eqFormat{\refEquation{impl-cons-exterior-data-must-be-available}}$ in dissertation
constraint
  forall (d in allDataInFunction diff statesInFunction )
  ( if valueMustBeAvailable(d)
    then loc[d] != locValueForInt /\ loc[d] != locValueForKilled
    else true
    endif
  );

% If an exterior operand does not take its min value, then its match must
% be selected and hence the datum cannot be in the intermediate value nor
% killed location.
%
% $\eqFormat{\refEquation{impl-cons-input-operands-not-taking-min-value}}$ in dissertation
constraint
  forall ( m in allMatches
         , p in operandsUsedByMatch[m] intersect operandsExteriorToMatch[m]
                where card(operandAlternatives[p]) > 1
                   /\ not valueOfOpMustBeAvailable(p)
         )
  ( alt[p] != min(operandAlternatives[p])
    ->
    (loc[Alt(p)] != locValueForInt /\ loc[Alt(p)] != locValueForKilled)
  );

% Constrain the location of d to be where its definers can put it.
%
% $\eqFormat{\refEquation{impl-cons-locs-of-defs}}$ in dissertation
constraint
  forall (d in allDataInFunction diff statesInFunction)
  ( let { array[int] of int: P =
            [p | m in defsetOfDatum[d] diff killInstrMatches
               , p in operandsDefinedByMatch[m]
                 where d in operandAlternatives[p]
            ]
        , array[int] of int: I =
            [ i | i in index_set_1of2(validDataLocRangesInMatch)
                  where validDataLocRangesInMatch[i, 2] in {p | p in P}
            ]
        }
    in if length(P) = length(I)
       then let { set of int: L =
                    { l | l in canonicalDataLocs
                        , i in I
                          where l in validDataLocRangesInMatch[i, 3]
                                     ..
                                     validDataLocRangesInMatch[i, 4]
                    }
                }
            in if card(L) < card(canonicalDataLocs)
               then loc[d] in L union {locValueForInt, locValueForKilled}
               else true
               endif
       else true
       endif
  );

% Constrain the location of d to be where its users can access it. Valid for
% such d that are used at least once.
%
% $\eqFormat{\refEquation{impl-cons-locs-of-uses}}$ in dissertation
constraint
  forall (d in allDataInFunction)
  ( let { array[int] of int: P =
            [ p | p in array_union(operandsUsedByMatch) diff killOperands
                  where d in operandAlternatives[p]
            ]
        , array[int] of int: I =
            [ i | i in index_set_1of2(validDataLocRangesInMatch)
                  where validDataLocRangesInMatch[i, 2] in {p | p in P}
            ]
        }
    in if length(P) > 0 /\ length(P) = length(I)
       then let { set of int: L =
                    { l | l in canonicalDataLocs
                        , i in I
                          where l in validDataLocRangesInMatch[i, 3]
                                     ..
                                     validDataLocRangesInMatch[i, 4]
                    }
                }
            in if card(L) < card(canonicalDataLocs)
               then loc[d] in L union {locValueForInt, locValueForKilled}
               else true
               endif
       else true
       endif
  );


%==================
% SOLVE AND OUTPUT
%==================

solve
  :: seq_search(
       [ % Try the smallest cost for the operation with the largest
         % difference between its two smallest values.
         int_search(opcosts, max_regret, indomain_min, complete)
         % Remaining decisions are left to the solver.
       ])
  minimize totalcost;

% oplace, omatch, dmatch are handy for debugging
output [ "sel=", show(sel), "\n"
       , "alt=", show([ if not fix(sel[matchOfP[p]])
                        then datumValueForNull
                        else alt[p] endif
                      | p in allOperands
                      ]), "\n"
       , "dplace=", show(dplace), "\n"
       , "loc=", show(loc), "\n"
       , "place=", show([ if not fix(sel[m])
                          then blockValueForNull
                          else if card(operationsCoveredByMatch[m]) = 0
                               then min(entryBlockOfMatch[m])
                               else oplace[opOfM[m]]
                               endif
                          endif
                        | m in allMatches
                        ]), "\n"
       , "oplace=", show(oplace), "\n"
       , "omatch=", show(omatch), "\n"
       , "dmatch=", show(dmatch), "\n"
       , "succ=", show(succ), "\n"
       , "entry=", show(entryBlockOfFunction), "\n"
       , "block_value_for_null=", show(blockValueForNull), "\n"
       , "loc_value_for_int=", show(locValueForInt), "\n"
       , "loc_value_for_killed=", show(locValueForKilled), "\n"
       , "alt_value_for_null=", show(datumValueForNull), "\n"
       , "cost=", show(execFrequencyGCD * totalcost), "\n"
       ];
