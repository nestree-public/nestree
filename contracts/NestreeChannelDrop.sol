pragma solidity ^0.5.10;

import "./SafeMath.sol";
import "./Ownable.sol";

contract ERC20
{
    function balanceOf(address _who) view public returns (uint256) {}
    function transfer(address _to, uint256 _value) public returns (bool) {}
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {}
    function allowance(address _owner, address _spender) view external returns (uint256) {}
}

contract NestreeChannelDrop is Ownable
{
    using SafeMath for uint256;

    string constant internal ERROR_VALUE_NOT_VALID             = 'Reason: Value must be greater than 0.';
    string constant internal ERROR_BALANCE_NOT_ENOUGH          = 'Reason: Balance is not enough.';

    address public _owner;

    mapping (address => address) private channelMasters;
    mapping (address => address) private proposedChannelMasters;
    mapping (address => mapping(address => uint256)) balances;

    event TransferChannelMaster(address indexed previousMaster, address indexed newMaster);
    event Deposit(address indexed sender, address indexed channelAddress, address indexed tokenAddress, uint256 amount);
    event Withdraw(address indexed channelAddress, address indexed receiver, uint256 amount);
    event Drop(address _tokenAddress, address[] _toList, uint256[] _amountList);

    constructor() public
    {
        _owner = msg.sender;
    }

    function isMaster(address _channelAddress, address _target) external returns (bool)
    {
        return channelMasters[_channelAddress] == _target;
    }

    function proposeMaster(address _channelAddress, address _newMaster) external
    {
        require(channelMasters[_channelAddress] == msg.sender, ERROR_NO_HAVE_PERMISSION);
        require(msg.sender != _newMaster, ERROR_CALLER_ALREADY_MASTER);
        proposedChannelMasters[_channelAddress] = _newMaster;
    }

    function claimChannelMaster(address _channelAddress) external
    {
        require(msg.sender == proposedChannelMasters[_channelAddress], ERROR_NOT_PROPOSED_MASTER);

        emit TransferChannelMaster(channelMasters[_channelAddress], msg.sender);

        channelMasters[_channelAddress] = msg.sender;
        proposedChannelMasters[_channelAddress] = address(0);
    }

    // 컨트랙트 주소에 approve를 해야 deposit 할 수 있음
    function deposit(address _channelAddress, address _tokenAddress, uint256 _amount) external
    {
        require(_channelAddress != address(0), ERROR_ADDRESS_NOT_VALID);
        require(_tokenAddress != address(0), ERROR_ADDRESS_NOT_VALID);
        require(_amount != 0, ERROR_VALUE_NOT_VALID);

        ERC20 token = ERC20(_tokenAddress);
        uint256 balance = token.allowance(msg.sender, address(this));
        require(balance >= _amount, ERROR_BALANCE_NOT_ENOUGH);
        token.transferFrom(msg.sender, address(this), _amount);
        balances[_channelAddress][_tokenAddress] = balances[_channelAddress][_tokenAddress].add(_amount);

        if(channelMasters[_channelAddress] == address(0))
        {
            channelMasters[_channelAddress] = msg.sender;
        }

        emit Deposit(msg.sender, _channelAddress, _tokenAddress, _amount);
    }

    function withdraw(address _from, address _tokenAddress, uint256 _amount) external
    {
        _withdraw(_from, _tokenAddress, msg.sender, _amount);
    }

    function withdrawTo(address _from, address _tokenAddress, address _to, uint256 _amount) external
    {
        _withdraw(_from, _tokenAddress, _to, _amount);
    }

    function _withdraw(address _from, address _tokenAddress, address _to, uint256 _amount) internal
    {
        require(_from != address(0), ERROR_ADDRESS_NOT_VALID);
        require(_tokenAddress != address(0), ERROR_ADDRESS_NOT_VALID);
        require(amount != 0, ERROR_VALUE_NOT_VALID);
        require(channelMasters[_from] == msg.sender, ERROR_NO_HAVE_PERMISSION);

        ERC20 token = ERC20(_tokenAddress);
        require(balances[_from][_tokenAddress] >= amount);
        token.transfer(_to, amount);
        balances[_from][_tokenAddress] = balances[_from][_tokenAddress].sub(amount);

        emit Withdraw(_from, _to, amount);
    }

    function balanceOf(address _tokenAddress, address _channelAddress) public view returns (uint256)
    {
        ERC20 token = ERC20(_tokenAddress);
        return token.balanceOf(address(this));
    }

    function drop(address _tokenAddress, address[] calldata _toList, uint256[] calldata _amountList) external
    {
        require(_tokenAddress != address(0), 'Token address is not valid');
        require(_toList.length == _amountList.length, 'Not valid list length');

        ERC20 token = ERC20(_tokenAddress);

        uint256 sumOfBalances = 0;
        for(uint256 i=0; i<_amountList.length; i++)
        {
            sumOfBalances = sumOfBalances.add(_amountList[i]);
        }

        // 합계가 발란스보다 많은지 체크
        uint256 balance = token.allowance(msg.sender, _self);

        require(balance >= sumOfBalances);

        for(uint256 i=0; i<_toList.length; i++)
        {
            token.transferFrom(msg.sender, _toList[i], _amountList[i]);
        }

        emit Drop(_tokenAddress, _toList, _amountList);
    }
}