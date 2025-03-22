// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

contract DecentralizedInsurance {
    address public admin;
    uint256 private policyCounter;
    uint256 public agentCommission = 10; // 10% commission for agents
    uint256 public adminCommission = 5; // 5% commission for the admin
    
    // Structure to define an insurance policy
    struct Policy {
        uint256 policyId;
        string name;
        uint256 premium;
        uint256 coverageAmount;
    }

    // Structure to store user policies and claim status
    struct UserPolicy {
        uint256 policyId;
        address insuranceCompany;
        uint256 startDate;
        uint256 endDate;
        bool claimed;
        ClaimStatus status;
    }

    // Enum to track claim states
    enum ClaimStatus { None, Received, Reviewing, Approved }
    
    // Structure to store transaction details
    struct Transaction {
        address sender;
        uint256 amount;
        uint256 timestamp;
    }

    // Mappings for policy storage and transactions
    mapping(address => Policy[]) public companyPolicies;
    mapping(address => UserPolicy[]) public userPolicies;
    mapping(address => Transaction[]) public userTransactions;
    mapping(address => Transaction[]) public companyTransactions;

    // Events to log important actions
    event PolicyCreated(uint256 policyId, string name, uint256 premium, uint256 coverageAmount);
    event PolicyPurchased(address indexed user, uint256 policyId, uint256 amount);
    event PolicyClaimed(address indexed user, uint256 policyId, ClaimStatus status);

    // Modifier to restrict access to admin-only functions
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    // Function to create a new insurance policy
    function createPolicy(string memory _name, uint256 _premium, uint256 _coverageAmount) public {
        policyCounter++;
        companyPolicies[msg.sender].push(Policy(policyCounter, _name, _premium, _coverageAmount));
        emit PolicyCreated(policyCounter, _name, _premium, _coverageAmount);
    }

    // Function to allow users to purchase a policy and split payments accordingly
    function policyPurchase(address _company, uint256 _policyId) public payable {
        Policy[] storage policies = companyPolicies[_company];
        Policy memory selectedPolicy;
        bool policyFound = false;
        
        // Find the specified policy
        for (uint256 i = 0; i < policies.length; i++) {
            if (policies[i].policyId == _policyId) {
                selectedPolicy = policies[i];
                policyFound = true;
                break;
            }
        }

        require(policyFound, "Policy Not Found");
        require(msg.value == selectedPolicy.premium, "Incorrect premium amount");
        
        // Calculate commission shares
        uint256 agentShare = (msg.value * agentCommission) / 100;
        uint256 adminShare = (msg.value * adminCommission) / 100;
        uint256 companyShare = msg.value - (agentShare + adminShare);
        
        // Transfer shares to respective parties
        payable(_company).transfer(companyShare);
        payable(admin).transfer(adminShare);
        
        // Store user policy details and transactions
        userPolicies[msg.sender].push(UserPolicy(_policyId, _company, block.timestamp, block.timestamp + 365 days, false, ClaimStatus.None));
        userTransactions[msg.sender].push(Transaction(msg.sender, msg.value, block.timestamp));
        companyTransactions[_company].push(Transaction(msg.sender, msg.value, block.timestamp));
        
        emit PolicyPurchased(msg.sender, _policyId, msg.value);
    }

    // Function for users to request a claim
    function requestClaim(uint256 _policyId) public {
        UserPolicy[] storage policies = userPolicies[msg.sender];
        bool policyExists = false;
        
        for (uint256 i = 0; i < policies.length; i++) {
            if (policies[i].policyId == _policyId) {
                require(!policies[i].claimed, "Claim already requested");
                require(block.timestamp <= policies[i].endDate, "Policy expired");
                
                policies[i].claimed = true;
                policies[i].status = ClaimStatus.Received;
                policyExists = true;
                break;
            }
        }
        require(policyExists, "Policy not found");
        emit PolicyClaimed(msg.sender, _policyId, ClaimStatus.Received);
    }

    // Function for the admin to update claim status
    function updateClaimStatus(address _user, uint256 _policyId, ClaimStatus _status) public onlyAdmin {
        UserPolicy[] storage policies = userPolicies[_user];
        bool updated = false;
        
        for (uint256 i = 0; i < policies.length; i++) {
            if (policies[i].policyId == _policyId && policies[i].claimed) {
                policies[i].status = _status;
                updated = true;
                break;
            }
        }
        require(updated, "Claim not found or not requested");
        emit PolicyClaimed(_user, _policyId, _status);
    }

    // Function to retrieve all transactions of a user
    function getUserTransactions(address _user) public view returns (Transaction[] memory) {
        return userTransactions[_user];
    }

    // Function to retrieve all transactions of a company
    function getCompanyTransactions(address _company) public view returns (Transaction[] memory) {
        return companyTransactions[_company];
    }

    // Function to retrieve all policies offered by a company
    function getCompanyPolicies(address _company) public view returns (Policy[] memory) {
        return companyPolicies[_company];
    }

    // Function to retrieve all policies a user has purchased
    function getUserPolicies(address _user) public view returns (UserPolicy[] memory) {
        return userPolicies[_user];
    }
}
