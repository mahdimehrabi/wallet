pragma solidity 0.8.15;


contract Wallet {
    struct Applicant {
        bool canceled ;
        bool won ;
        uint8 acceptVotesCount;
        uint8 cancelVotesCount;
        address[] participants;
        uint introduceTime ;
    }

    address payable public owner;
    address[5] public guardians;
    mapping(address => Applicant) public  owner_applicants_votes;
    address[] public  applicants;

    receive() external payable {}

    constructor() {
        owner = payable(msg.sender);
    }

    function send(uint256 amount, address payable _to) public {
        cancelPendingOwners();
        require(address(msg.sender) == owner, "access_denied");
        require(address(this).balance >= amount, "balance_not_enough");
        require(amount > 0, "balance_less_receivethan_zero");
        (bool ok, ) = _to.call{value: amount}("");
        require(ok, "failed_to_send");
    }

    function SendToSafe(address payable _to, uint256 amount) external {
        cancelPendingOwners();
        require(address(msg.sender) == owner, "access_denied");
        require(address(this).balance >= amount, "balance_not_enough");
        require(amount > 0, "balance_less_than_zero");
        (bool ok, ) = _to.call{value: amount}("");
        require(ok, "failed_to_send");
    }

    function DepositToSafe(address payable _to, uint256 amount) external {
        cancelPendingOwners();
        require(address(msg.sender) == owner, "access_denied");
        require(address(this).balance >= amount, "balance_not_enough");
        require(amount > 0, "balance_less_than_zero");
        (bool ok, ) = _to.call{value: amount}(
            abi.encodeWithSignature("deposit()")
        );
        require(ok, "failed_to_send");
    }

    function SetGuardians(address[5] calldata _guardians) public {
        cancelPendingOwners();
        require(address(msg.sender) == owner, "access_denied");
        guardians = _guardians;
    }


    function Vote(address applicant, int8 vote) external {
        require(vote==1||vote==-1,"vote is not valid");
        
        checkIsGuardian();
        
        Applicant storage applicantObj=owner_applicants_votes[applicant];
        require(applicantObj.participants.length>0,"not_exist");
        //check its created at least one month ago
        uint monthAgo=block.timestamp-(86400*30);
        require(applicantObj.introduceTime<monthAgo,"must_month_ago");

        //check guradian already not voted
        bool alreadyVoted=false;
        for (uint8 i = 0; i < applicantObj.participants.length; i++) {
            if (applicantObj.participants[i] == address(msg.sender)) {
                alreadyVoted=true;
                break;
            }
        }
        require(!alreadyVoted,"you already vote");
        require(!applicantObj.canceled && !applicantObj.canceled,"canceled or won");
        //check applicant woned and not canceled
        if (vote==1){
        applicantObj.acceptVotesCount++;
        }else {
        applicantObj.acceptVotesCount--;
        }
        if (applicantObj.acceptVotesCount>=3){
            owner=payable(applicant);
            applicantObj.won=true;
        }else if(applicantObj.cancelVotesCount>=3){
          applicantObj.canceled=true;
        }
    }

    function newOwner(address applicant) public {
        checkIsGuardian();
        require(owner_applicants_votes[applicant].participants.length<1,"already_exist");
        owner_applicants_votes[applicant].acceptVotesCount=1;
        owner_applicants_votes[applicant].participants.push(msg.sender);
        owner_applicants_votes[applicant].introduceTime=block.timestamp;
        applicants.push(applicant);
    }

    function checkIsGuardian() private {
        bool is_guardian = false;
        for (uint8 i = 0; i < guardians.length; i++) {
            if (guardians[i] == address(msg.sender)) {
                is_guardian = true;
                break;
            }
        }
        require(is_guardian, "access_denied");
    }

    function cancelPendingOwners() private {
        if (msg.sender==owner){
            for(uint i=0;i<applicants.length;i++){
                owner_applicants_votes[applicants[i]].canceled=true;
            }
        }
    }
}

contract Safe {
    mapping(address => uint256) public savings;

    function deposit() public payable {
        savings[msg.sender] += msg.value;
    }

    receive() external payable {
        deposit();
    }
}
