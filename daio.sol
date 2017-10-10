pragma solidity ^0.4.15;

contract Daio {
    uint public membersMinimum = 2;
    Member[] public members;
    mapping(address => uint256) public memberId;
    event MembershipChanged(address member, bool isMember);

    uint public fundTotal;
    uint public fundShare;
    uint public fundingMinimumTime;
    event FundingChanged(uint total);
    event SurplusReturned(uint share, uint shareMax, uint surplus);
    bool public fundActive = false;
    uint public fundMinimumTime;
    event FundLiquidated(address member, string name, uint share);

    struct Member {
        address member;
        string name;
        uint share;
    }

    modifier onlyMembers {
        require(memberId[msg.sender] != 0);
        _;
    }

    modifier onlyNewMembers {
        require(memberId[msg.sender] == 0);
        _;
    }

    function Daio(uint fundingMinimumMinutes) payable public {
        require(msg.value > 0);
        fundingMinimumTime = now + fundingMinimumMinutes * 1 minutes;
        addMember(0, "daio", 0);
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
        MembershipChanged(member, true);
    }

    function removeMember (uint id) private {
        address member = members[id].member;
        memberId[member] = 0;
        delete members[id];
        members.length--;
    }

    function contributeFund(string memberName) payable onlyNewMembers public {
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
        require(members.length >= membersMinimum);
        fundActive = true;
        fundMinimumTime = now + fundMinimumMinutes * 1 minutes;
    }

    function liquidateFund() onlyMembers payable public {
        require(now >= fundMinimumTime);
        require(fundActive);
        fundActive = false;
        uint membersTotal = members.length - 1;
        uint share = fundTotal / membersTotal;
        for (uint i = 1; i < members.length; i++) {
            members[i].member.transfer(share);
            FundLiquidated(members[i].member, members[i].name, share);
        }
        for (i = 1; i < members.length; i++) {
            removeMember(i);
        }
        fundTotal = 0;
        fundShare = 0;
    }
}
