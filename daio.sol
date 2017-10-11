pragma solidity ^0.4.15;

contract Daio {
    uint public membersMinimum = 2;
    uint public membersTotal;
    Member[] public members;
    mapping(address => uint256) public memberId;
    event MembershipChanged(address member, bool isMember);

    struct Member {
        address member;
        string name;
        uint share;
    }

    uint public fundTotal;
    uint public fundShare;
    uint public fundingMinimumTime;
    uint public fundMinimumTime;
    bool public fundActive = false;
    event FundingChanged(uint total);
    event SurplusReturned(uint share, uint shareMax, uint surplus);
    event FundLiquidated(address member, string name, uint share);

    uint public proposalsTotal;
    Proposal[] public proposals;
    event ProposalAdded(uint proposalId, address recipient, uint volume, uint price);
    event ProposalPassed(uint proposalId, bool passed, uint votesFor);
    event ProposalExecuted(uint proposalId, address recipient, uint volume, uint price);

    struct Proposal {
        address recipient;
        uint volume;
        uint price;
        string description;
        uint deadline;
        bool passed;
        bool executed;
        bytes32 proposalHash;
        uint votesFor;
        uint votesTotal;
        Vote[] votes;
        mapping(address => bool) voted;
    }

    event Voted(uint proposalId, bool support, address member);

    struct Vote {
        address member;
        bool support;
    }

    modifier onlyMembers {
        require(memberId[msg.sender] != 0);
        _;
    }

    modifier onlyNew {
        require(memberId[msg.sender] == 0);
        _;
    }

    function Daio(uint fundingMinimumMinutes) payable public {
        require(msg.value > 0);
        fundingMinimumTime = now + fundingMinimumMinutes * 1 minutes;
        addMember(0, "daio", 0); // dummy daio for member 0
        addMember(msg.sender, "founder", msg.value);
        fundShare = msg.value;
        fundTotal += msg.value;
        FundingChanged(fundTotal);
    }

    function addMember (address member, string name, uint share) private {
        uint id = memberId[member];
        if (id == 0) {
            memberId[member] = members.length;
            id = members.length++;
        }
        members[id] = Member({
            member: member,
            name: name,
            share: share
        });
        membersTotal = id;
        MembershipChanged(member, true);
    }

    function removeMember (uint id) private {
        address member = members[id].member;
        memberId[member] = 0;
        delete members[id];
        members.length--;
    }

    function contributeFund(string memberName) payable onlyNew public {
        require(!fundActive);
        require(msg.value >= fundShare);
        uint share = msg.value;
        if (fundShare == 0) { // first contribution
            fundShare = share;
        }
        if (share > fundShare) {
            uint surplus = share - fundShare;
            share -= surplus;
            msg.sender.transfer(surplus);
            SurplusReturned(msg.value, fundShare, surplus);
        }
        addMember(msg.sender, memberName, share);
        fundTotal += share;
        FundingChanged(fundTotal);
    }

    function launchFund(uint fundMinimumMinutes) onlyMembers public {
        require(now >= fundingMinimumTime);
        require(!fundActive);
        require(members.length-1 >= membersMinimum);
        fundActive = true;
        fundMinimumTime = now + fundMinimumMinutes * 1 minutes;
    }

    function addProposal(
        address recipient,
        uint volume,
        uint price,
        string description,
        uint votingMinutes,
        bytes transactionBytecode
    ) onlyMembers public
    {
        require(fundActive == true);
        uint proposalId = proposals.length++;
        Proposal storage p = proposals[proposalId]; // construct explicitly
        p.recipient = recipient;
        p.volume = volume;
        p.price = price;
        p.description = description;
        p.deadline = now + votingMinutes * 1 minutes;
        p.passed = false;
        p.executed = false;
        p.votesFor = 0;
        p.votesTotal = 0;
        p.proposalHash = keccak256(recipient, volume, price, transactionBytecode);
        proposalsTotal = proposals.length;
        ProposalAdded(proposalId, recipient, volume, price);
    }

    function voteProposal(uint proposalId, bool support) onlyMembers public {
        Proposal storage p = proposals[proposalId];
        require(!p.voted[msg.sender]);
        require(now <= p.deadline);
        p.voted[msg.sender] = true;
        uint voteId = p.votes.length++;
        p.votesTotal = p.votes.length;
        if (support) {
            p.votesFor += 1;
        }
        p.votes[voteId] = Vote({
            member: msg.sender,
            support: support
        });
        Voted(proposalId, support, msg.sender);
        if (p.votesFor > membersTotal / 2) { // simple majority (>50%). Note: standard integer division returns floor
            p.passed = true;
            ProposalPassed(proposalId, true, p.votesFor);
        }
    }

    function liquidateFund() onlyMembers payable public {
        require(now >= fundMinimumTime);
        require(fundActive);
        fundActive = false;
        uint share = fundTotal / membersTotal;
        for (uint i = 1; i < members.length; i++) {
            members[i].member.transfer(share);
            FundLiquidated(members[i].member, members[i].name, share);
        }
        for (i = 1; i < members.length; i++) {
            removeMember(i);
        }
        membersTotal = 0;
        fundTotal = 0;
        fundShare = 0;
    }
}
