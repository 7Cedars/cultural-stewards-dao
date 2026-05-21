// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";  

import { PowersTypes } from "@lib/powers-monorepo/solidity/src/interfaces/PowersTypes.sol";
import { Powers } from "@lib/powers-monorepo/solidity/src/Powers.sol";
import { PowersFactory } from "@lib/powers-monorepo/solidity/src/helpers/PowersFactory.sol";  
import { DeployHelpers } from "@lib/powers-monorepo/solidity/governance/DeployHelpers.s.sol";
import { Configurations } from "@lib/powers-monorepo/solidity/script/Configurations.s.sol";

import { ElectionRegistry } from "@lib/powers-monorepo/solidity/src/helpers/ElectionRegistry.sol";
import { Soulbound1155 } from "@lib/powers-monorepo/solidity/test/mocks/Soulbound1155.sol";
import { MandateRegistry } from "@lib/powers-monorepo/solidity/src/helpers/MandateRegistry.sol";

abstract contract DeploySetup is DeployHelpers {
    Configurations helperConfig = new Configurations();
    MandateRegistry registry = MandateRegistry(0x97b66F08Eb857e27A24492D338d3DC484DF63896); 

    address cedars = 0x95e51Ce331e9F81917d729C5b1F9127ca1138a01; // privy AA. 
    address hannah = 0xc9ce1DC547C42F66464f5a7f0E3cd60EBf1C5Bd2;
    string baseURI = "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafybeifteuvxskmzqraitv3ho2gd7k5gbdjdt7uptxwqnojwituu5llcfy/";
    
    uint256 constitutionLength; 
    address[] targets;
    uint256[] values;
    bytes4[] functionSelectors;
    bytes[] calldatas;
    string[] inputParams;
    string[] dynamicParams;
    uint16 mandateCount;
    address treasury;
    address paymaster;

    uint256 internal blocksPerHour; // to be set in setUp() of inheriting contracts.  

    // Cached mandate addresses — populated per-layer via _initMandateAddresses().
    address internal m_Adopt_Mandates;
    address internal m_BespokeAction_Advanced;
    address internal m_BespokeAction_OnReturnValue;
    address internal m_BespokeAction_Simple;
    address internal m_ElectionRegistry_CleanUpVoteMandate;
    address internal m_ElectionRegistry_CreateVoteMandate;
    address internal m_ElectionRegistry_Nominate;
    address internal m_ElectionRegistry_Tally;
    address internal m_ElectionRegistry_Vote;
    address internal m_ExternalAction_Flexible;
    address internal m_ExternalAction_OnReturnValue;
    address internal m_ExternalAction_Simple;
    address internal m_GovernedToken_GatedAccess;
    address internal m_GovernedToken_MintEncodedToken;
    address internal m_Nominate;
    address internal m_PauseMandates;
    address internal m_PeerSelect;
    address internal m_PresetActions;
    address internal m_PresetActions_OnOwnPowers;
    address internal m_SafeAllowance_Action;
    address internal m_SafeAllowance_Transfer;
    address internal m_Safe_ExecTransaction;
    address internal m_Safe_ExecTransaction_OnReturnValue;
    address internal m_Safe_RecoverTokens;
    address internal m_StatementOfIntent;
    address internal m_ZKPassport_Check;

    // The mandate version to be used.
    uint16 constant MAJOR = 0;
    uint16 constant MINOR = 1;
    uint16 constant PATCH = 7;

    uint16 constant PACKAGE_SIZE = 7;  
}

