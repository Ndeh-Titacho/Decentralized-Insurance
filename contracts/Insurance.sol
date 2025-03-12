// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;


contract decentralizedInsurance{

    address public admin;

    //unique policy id tracker
    uint256 private policyCounter;

//structure to store policy details
    struct Policy{
        uint256 policyId;
        string name;
        uint256 premium; //amount to be paid for this policy
        uint256 coverageAmount; //maximum claimable amount

    }

//structure to store the users policy details
    struct UserPolicy {
        uint256 policyId;
        address insuranceCompany;
        uint256 startDate;
        uint256 endDate;
        bool claimed;
        bool approved;
    }


    //mapping from insurance company to their available policies
    mapping(address => Policy[]) public companyPolicies;
    //mapping from users to their purchased policies
    mapping(address => UserPolicy[]) public userPolicies;


    //events
    event PolicyCreated(uint256 _policyId, string _name, uint256 _premium, uint256 _coverageAmount);
    event PolicyPurchased(address indexed _user, uint256 _policyId);
    event PolicyClaimed(address indexed _user, uint256  _policyId);
    event PolicyApproved(address indexed _user, uint256 _policyId);


    //modifier for admin access
    modifier onlyAdmin(){
        require(msg.sender == admin,"Only admin can perform this action");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function createPolicy(string memory _name, uint256 _premium, uint256 _coverageAmount) public {
        //uniqu policy ID
        policyCounter++;
        companyPolicies[msg.sender].push(Policy(policyCounter, _name, _premium,_coverageAmount));

        emit PolicyCreated(policyCounter, _name, _premium,_coverageAmount);
    }


    function policyPurchase(address _company, uint256 _policyId) public payable {
        //get policies from specified company
        Policy[] storage policies = companyPolicies[_company];

        //find the selected policy
        Policy memory selectedPolicy;
        bool policyFound = false;

        for(uint256 i =0; i< policies.length ; i++){
            if(policies[i].policyId == _policyId){
                selectedPolicy = policies[i];
                policyFound = true;
                break;
            }


        }

        require(policyFound, "Policy Not Found");
        require(msg.value == selectedPolicy.premium, "Incorrect premium amount");


        //store purchased policy in userPolicies
        userPolicies[msg.sender].push(UserPolicy(_policyId,_company,block.timestamp, block.timestamp + 356 days,false,false));

        emit PolicyPurchased(msg.sender, _policyId);

    }



    function requestClaim(uint256 _policyId) public {
        UserPolicy[] storage policies = userPolicies[msg.sender];
        bool policyExist = false;

        for(uint256 i = 0 ; i < policies.length; i++){
            if(policies[i].policyId == _policyId){
                require(!policies[i].claimed, "A claim has already been made for this policy");
                require(block.timestamp <= policies[i].endDate, "Policy has expired");

                policies[i].claimed = true;
                policyExist = true;
                break;
            }
        }

        require(policyExist,"Policy not found");

        emit PolicyClaimed(msg.sender, _policyId);

    }


    function approveClaim(address _user, uint256 _policyId) public onlyAdmin{
         UserPolicy[] storage policies = userPolicies[_user];
        bool claimApproved = false;

        for (uint256 i = 0; i < policies.length; i++) {
            if (policies[i].policyId == _policyId && policies[i].claimed && !policies[i].approved) {
                policies[i].approved = true;
                claimApproved = true;
                break;
            }
        }

        require(claimApproved, "Claim not found or already approved");

        emit PolicyClaimed(_user, _policyId);
    }


     function getCompanyPolicies(address _company) public view returns (Policy[] memory) {
        return companyPolicies[_company];
    }


    function getUserPolicies(address _user) public view returns (UserPolicy[] memory) {
        return userPolicies[_user];
    }

}