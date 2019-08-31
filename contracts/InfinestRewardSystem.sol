pragma solidity ^0.5.11;

import "./SafeMath.sol";
import "./InfinestOwnable.sol";

contract ERC20
{
    function balanceOf(address _who) view public returns (uint256) {}
    function transfer(address _to, uint256 _value) public returns (bool) {}
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {}
    function allowance(address _owner, address _spender) view external returns (uint256) {}
}

contract InfinestRewardSystem is InfinestOwnable
{
    using SafeMath for uint256;

    // MARK: error messages
    string constant internal ERROR_NOT_EQUALS_LIST_LENGTH    = 'Reason: Length of parameters is not equals.';
    string constant internal ERROR_INVALID_RECEIVER_ADDRESS  = 'Reason: Invalid receiver address.';
    string constant internal ERROR_INVALID_CHANNEL_ADDRESS   = 'Reason: Invalid address of channel.';
    string constant internal ERROR_INVALID_ERC20_ADDRESS     = 'Reason: Invalid address of ERC20.';
    string constant internal ERROR_INVALID_AMOUNT            = 'Reason: Invalid amount.';
    string constant internal ERROR_INVALID_SENDER_BALANCE    = 'Reason: Invalid balance of sender.';
    string constant internal ERROR_INVALID_CONTRACT_BALANCES = 'Reason: Invalid balance of contract ERC20.';
    string constant internal ERROR_INVALID_CHANNEL_BALANCE   = 'Reason: Invalid balance of channel ERC20';

    // MARK: information
    string constant public version = '0.1';

    // MARK: properties
    address public _self;
    address[] public tokens; // 현재 컨트랙트에서 사용된적이 있는 토큰 목록
    mapping(address => mapping(address => uint256)) public balances; // 채널 지갑 주소에 입금된 토큰별 잔액

    // MARK: events
    event Migration(address _new, address _tokenAddress, uint256 _amount);
    event Deposit(address _from, address _channelAddress, address _tokenAddress, uint256 amount);
    event Withdraw(address _channelAddress, address _tokenAddress, address _to, uint256 amount);
    event Drop(address _channelAddress, address _tokenAddress, address[] receivers, uint256[] amounts);

    constructor() public
    {
        _self = address(this);
    }

    // MARK: privates
    function _addToken(address _tokenAddress) internal returns (bool)
    {
        uint256 length = tokens.length;
        for(uint256 i=0; i<length; i++)
        {
            if(tokens[i] == _tokenAddress)
            {
                return true;
            }
        }

        tokens.push(_tokenAddress);
        return true;
    }

    // MARK: system functions
    function migration(address _new) external onlyOwner
    {
        // 컨트랙트 업그레이드를 위해서 이 컨트랙트가 가지고 있는 모든 토큰을 옮기는 작업

        uint256 length = tokens.length;
        for(uint256 i=0; i<length; i++)
        {
            ERC20 _token = ERC20(tokens[i]);
            uint256 balance = _token.balanceOf(_self);
            _token.transfer(_new, balance);

            emit Migration(_new, tokens[i], balance);
        }
    }

    // MARK: channel wallet functions
    function deposit(address _from, address _channelAddress, address _tokenAddress, uint256 _amount) external hasPermission
    {
        // 채널 지갑에 토큰을 입금하는 함수. 네스트리 사용자가 컨트랙트에 approve를 해주면 manager가 이 함수를 호출한다.
        // _from은 approve를 호출한 네스트리 사용자 지갑의 주소임.
        // 따라서 _from에서 컨트랙트 주소로 토큰을 옮겨야 함.

        require(_from != address(0), 'Reason: invalid address of from.');
        require(_channelAddress != address(0), ERROR_INVALID_CHANNEL_ADDRESS);
        require(_tokenAddress != address(0), ERROR_INVALID_ERC20_ADDRESS);
        require(_amount > 0, ERROR_INVALID_AMOUNT);

        ERC20 _token = ERC20(_tokenAddress);
        require(_token.allowance(_from, _self) >= _amount, ERROR_INVALID_SENDER_BALANCE);
        _token.transferFrom(_from, _self, _amount);

        balances[_channelAddress][_tokenAddress] = balances[_channelAddress][_tokenAddress].add(_amount);

        _addToken(_tokenAddress);

        emit Deposit(_from, _channelAddress, _tokenAddress, _amount);
    }

    function withdraw(address _channelAddress, address _tokenAddress, address _receiver, uint256 _amount) external hasPermission
    {
        // 채널 지갑에서 토큰을 출금하는 함수. 네스트리 사용자가 출금요청을 하면 manager가 이 함수를 호출한다.
        // 매니저 지갑 pk가 유출됐을때를 대비해서 24시간 출금 제한을 걸어두는게 좋을듯 함.

        require(_channelAddress != address(0), ERROR_INVALID_CHANNEL_ADDRESS);
        require(_tokenAddress != address(0), ERROR_INVALID_ERC20_ADDRESS);
        require(_receiver != address(0), 'Reason: invalid address of receiver.');
        require(_amount > 0, ERROR_INVALID_AMOUNT);

        ERC20 _token = ERC20(_tokenAddress);
        require(balances[_channelAddress][_tokenAddress] >= _amount, ERROR_INVALID_CHANNEL_BALANCE); // 채널에 입금된 토큰 수량이 더 많아야 하고
        require(_token.balanceOf(_self) >= _amount, ERROR_INVALID_CONTRACT_BALANCES); // 실제 컨트랙트가 보유한 토큰 수량도 많아야 함.

        _token.transfer(_receiver, _amount);

        balances[_channelAddress][_tokenAddress] = balances[_channelAddress][_tokenAddress].sub(_amount);

        emit Withdraw(_channelAddress, _tokenAddress, _receiver, _amount);
    }

    function drop(address _channelAddress, address _tokenAddress, address[] calldata _receivers, uint256[] calldata _amounts) external hasPermission
    {
        // 채널 지갑에서 대규모 보상을 실행하는 함수.

        require(_channelAddress != address(0), ERROR_INVALID_CHANNEL_ADDRESS);
        require(_tokenAddress != address(0), ERROR_INVALID_ERC20_ADDRESS);
        require(_receivers.length != _amounts.length, ERROR_NOT_EQUALS_LIST_LENGTH);

        ERC20 _token = ERC20(_tokenAddress);

        uint256 _sum = 0;
        for(uint256 i=0; i<_amounts.length; i++)
        {
            require(_receivers[i] != address(0), ERROR_INVALID_RECEIVER_ADDRESS);
            _sum = _sum.add(_amounts[i]);
        }

        require(balances[_channelAddress][_tokenAddress] >= _sum, ERROR_INVALID_CHANNEL_BALANCE); // 채널에 입금된 토큰 수량이 더 많아야 하고
        require(_token.balanceOf(_self) >= _sum, ERROR_INVALID_CONTRACT_BALANCES); // 실제 컨트랙트가 보유한 토큰 수량도 많아야 함.

        for(uint256 i=0; i<_receivers.length; i++)
        {
            _token.transfer(_receivers[i], _amounts[i]);
        }

        balances[_channelAddress][_tokenAddress] = balances[_channelAddress][_tokenAddress].sub(_sum);

        emit Drop(_channelAddress, _tokenAddress, _receivers, _amounts);
    }

    function balanceOf(address _channelAddress, address _tokenAddress) external view returns (uint256)
    {
        // 채널 지갑이 가지고 있는 토큰 잔량 조회하는 함수

        require(_channelAddress != address(0), ERROR_INVALID_CHANNEL_ADDRESS);
        require(_tokenAddress != address(0), ERROR_INVALID_ERC20_ADDRESS);

        return balances[_channelAddress][_tokenAddress];
    }
}