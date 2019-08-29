pragma solidity ^0.5.11;

import "./SafeMath.sol";

// 이 코드는 임시 초대보상을 위한 코드입니다.
contract ERC20
{
    function balanceOf(address _who) view public returns (uint256) {}
    function transfer(address _to, uint256 _value) public returns (bool) {}
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {}
    function allowance(address _owner, address _spender) view external returns (uint256) {}
}

// 이 컨트랙트 주소에 approve를 먼저 해두고
contract NestreeDrop
{
    using SafeMath for uint256;

    // MARK: error messages
    string constant internal ERROR_NOT_EQUALS_LIST_LENGTH = 'Reason: length of parameters is not equals.';
    string constant internal ERROR_INVALID_TOKEN_ADDRESS  = 'Reason: invalid token address';
    string constant internal ERROR_INVALID_RECEIVER_ADDRESS  = 'Reason: invalid receiver address';

    // MARK: properties
    address public _self;

    // MARK: events
    event ReferralDrop(address _tokenAddress, address _inviter, uint256 _inviterAmount, address _participant, uint256 _participantAmount);

    constructor() public
    {
        _self = address(this);
    }

    function balanceOf(address _tokenAddress) public view returns (uint256)
    {
        ERC20 token = ERC20(_tokenAddress);
        return token.allowance(msg.sender, _self);
    }

    function drop(address _tokenAddress, address[] calldata receivers, uint256[] calldata amounts) external
    {
//        require(_tokenAddress != address(0), 'Reason: Invalid address of token');
//        require(_inviter != address(0), 'Reason: Invalid address of inviter');
//        require(_participant != address(0), 'Reason: Invalid address of participant');
//
//        require(_inviterAmount > 0, 'Reason: Invalid amount of inviter');
//        require(_participantAmount > 0, 'Reason: Invalid amount of participant');
//
//        ERC20 token = ERC20(_tokenAddress);
//
//        uint256 sumOfBalances = _inviterAmount.add(_participantAmount);
//
//        // 합계가 발란스보다 많은지 체크
//        uint256 balance = token.allowance(msg.sender, _self);
//        require(balance >= sumOfBalances);
//
//        token.transferFrom(msg.sender, _inviter, _inviterAmount);
//        token.transferFrom(msg.sender, _participant, _participantAmount);
//
//        emit ReferralDrop(_tokenAddress, _inviter, _inviterAmount, _participant, _participantAmount);
//
//        return true;
    }
}