// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


contract WalletAuth {
    using ECDSA for bytes32;

    //mapping to identify if user is authenticated or not
    mapping(address => bool) authenticatedUsers;

    //emits the address of an authenticated user
    event UserAuthenticated(address _user);

//function to hash user address + "Authenticate me"
    function getMessageHash(address _user) public pure returns (bytes32){
        return keccak256(abi.encodePacked(_user,"Authenticate me"));
    }

//function to authenticate user
    function authenticateUser(bytes memory _signature) public {

//variable to store message signed by user
        bytes32 hashedMessage = getMessageHash(msg.sender);
//variable to store signature of the message signed by the user with the private key
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",hashedMessage));


    //recover address of user from signature
        address recoveredAddress = ECDSA.recover(ethSignedMessageHash,_signature);
    //check if address is same as the one recovered from signature
        require(msg.sender == recoveredAddress, "Invalid signature");

    //if user address equals that from the signature we update the authenticatedUser mapping and emit the event
        authenticatedUsers[msg.sender] = true;
        emit UserAuthenticated(msg.sender);


    }

    function isUserAuthenticated(address _user) public view returns(bool){
        return authenticatedUsers[_user];
    }
}