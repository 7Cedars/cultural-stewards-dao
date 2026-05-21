// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import { Powers } from "@lib/powers-monorepo/solidity/src/Powers.sol";   
import { Deploy } from "@governance/Deploy.s.sol";
import { Configurations } from "@lib/powers-monorepo/solidity/script/Configurations.s.sol"; 
import { TestHelperFunctions } from "@lib/powers-monorepo/solidity/test/TestSetup.t.sol"; 
import { Initialise } from "@governance/actions/Initialise.s.sol";   

interface IAllowanceModule {
    function delegates(address safe, uint48 index) external view returns (address delegate, uint48 prev, uint48 next);
    function getTokenAllowance(address safe, address delegate, address token) external view returns (uint256[5] memory);
}

contract CulturalStewardsDAO_IntegrationTest is TestHelperFunctions {
    struct Mem {
        uint256 nonce;
    }
    Mem mem;

    // Deploy & config 
    Deploy deploy; 
    
    // layers
    address primaryLayer;
    address digitalAddress;
    address ideasLayerFactoryAddress;
    address convergenceLayerFactoryAddress;
    address primaryAddress; 
    address convergenceAddress;
    address ideasLayer0; 

    // actions 
    Initialise initialise;
    // assets, management, .. etc  

    address treasury;
    address safeAllowanceModule; 
    address testAccount1 = vm.addr(vm.envUint("TEST_ACCOUNT_KEY_1"));
    address testAccount2 = vm.addr(vm.envUint("TEST_ACCOUNT_KEY_2"));
    address testAccount3 = vm.addr(vm.envUint("TEST_ACCOUNT_KEY_3"));

    uint256 fork; 
    uint256 blocksPerHour;
    string[] ideasNames = ["Seeing", "Making", "Listening", "Telling", "Remembering", "Imagining", "Tending"];
    uint256[] privateKeys = [
        vm.envUint("TEST_ACCOUNT_KEY_1"), 
        vm.envUint("TEST_ACCOUNT_KEY_2"), 
        vm.envUint("TEST_ACCOUNT_KEY_3")
    ];

    function setUp() public {
        helperConfig = new Configurations();
        blocksPerHour = helperConfig.getBlocksPerHour(block.chainid);

        // the test always needs to run on a forked chain that has the Safe protocol deployed. 
        fork = vm.createFork(vm.envString("SEPOLIA_RPC_URL"));
        vm.selectFork(fork);

        // Deploy the initial organisations and factories. 
        deploy = new Deploy();        
        (primaryAddress, digitalAddress, ideasLayerFactoryAddress, convergenceLayerFactoryAddress) = deploy.run();
        

        // setting up the organisation (6 Ideas layes + 1 convergence layer)
        //1step 1 running setup mandates on Primary and Digital Layer. 
        initialise = new Initialise();
        initialise.runSetupMandate(primaryAddress, nonce, privateKeys);
        initialise.runSetupMandate(digitalAddress, nonce, privateKeys);

        // step 2: intialise Ideas Layers  
        initialise.deployIdeasLayer1(primaryAddress, nonce, ideasNames, privateKeys);
        
        vm.roll(block.number + minutesToBlocks(6, blocksPerHour)); // Advance some blocks to avoid same-block issues.

        initialise.deployIdeasLayer2(primaryAddress, nonce, ideasNames, privateKeys);
        vm.roll(block.number + minutesToBlocks(6, blocksPerHour)); // Advance some blocks to avoid same-block issues.

        initialise.deployIdeasLayer3(primaryAddress, nonce, ideasNames, privateKeys);
        vm.roll(block.number + minutesToBlocks(6, blocksPerHour)); // Advance some blocks to avoid same-block issues.

        // step 3: initialise Convergence Layer
        ideasLayer0 = Powers(payable(primaryAddress)).getRoleHolderAtIndex(4, 0);
        initialise.deployConvergenceLayer1(ideasLayer0, nonce, privateKeys);
        vm.roll(block.number + minutesToBlocks(6, blocksPerHour)); // Advance some blocks to avoid same-block issues.

        initialise.deployConvergenceLayer2(ideasLayer0, nonce, privateKeys);
        vm.roll(block.number + minutesToBlocks(8, blocksPerHour)); // Advance some blocks to avoid same-block issues.

        initialise.deployConvergenceLayer3(primaryAddress, ideasLayer0, nonce, privateKeys);
        vm.roll(block.number + minutesToBlocks(8, blocksPerHour)); // Advance some blocks to avoid same-block issues.

        initialise.deployConvergenceLayer4(primaryAddress, nonce, privateKeys);
        vm.roll(block.number + minutesToBlocks(8, blocksPerHour)); // Advance some blocks to avoid same-block issues.
        
        initialise.deployConvergenceLayer5(primaryAddress, nonce, privateKeys);
    }

    function test_initialise_cultural_stewards() public view {
        // check dependencies 
        check_inputParamsDependencies(primaryAddress); 
        check_inputParamsDependencies(digitalAddress); 
        check_inputParamsDependencies(ideasLayerFactoryAddress); 
        check_inputParamsDependencies(convergenceLayerFactoryAddress); 

        // check label role 
        vm.assertTrue(keccak256(abi.encodePacked(Powers(payable(primaryAddress)).getRoleLabel(1))) == keccak256(abi.encodePacked("Artist")), "Role 1 should be 'Artist'"); 
        vm.assertTrue(keccak256(abi.encodePacked(Powers(payable(primaryAddress)).getRoleLabel(2))) == keccak256(abi.encodePacked("Owner")), "Role 2 should be 'Owner'"); 
        vm.assertTrue(keccak256(abi.encodePacked(Powers(payable(primaryAddress)).getRoleLabel(3))) == keccak256(abi.encodePacked("Operator")), "Role 3 should be 'Operator'"); 
        vm.assertTrue(keccak256(abi.encodePacked(Powers(payable(primaryAddress)).getRoleLabel(4))) == keccak256(abi.encodePacked("Voter")), "Role 4 should be 'Voter'"); 
        vm.assertTrue(keccak256(abi.encodePacked(Powers(payable(primaryAddress)).getRoleLabel(5))) == keccak256(abi.encodePacked("Executive")), "Role 5 should be 'Executive'"); 
        
        // check that test Account 1 is executive 
        vm.assertTrue(Powers(payable(primaryAddress)).hasRoleSince(testAccount1, 5) > 0, "Test Account 1 should have Executive role");

        // check treasury 
        // vm.assertTrue(Powers(payable(primaryAddress)).getTreasury() == primaryAddress, "Treasury should be set as organisation itself.");
    }

}
