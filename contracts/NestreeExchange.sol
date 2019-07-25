pragma solidity ^0.5.10;

import "./SafeMath.sol";

contract ERC20
{
    function balanceOf(address _who) view public returns (uint256) {}
    function transfer(address _to, uint256 _value) public returns (bool) {}
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {}
    function allowance(address owner, address _spender) view external returns (uint256) {}
}

contract Ownable
{
    string constant internal ERROR_NO_HAVE_PERMISSION   = 'Reason: No have permission.';
    string constant internal ERROR_IS_STOPPED           = 'Reason: Is stopped.';
    string constant internal ERROR_ADDRESS_NOT_VALID    = 'Reason: Address is not valid.';
    string constant internal ERROR_CALLER_ALREADY_OWNER = 'Reason: Caller already is owner';
    string constant internal ERROR_NOT_PROPOSED_OWNER   = 'Reason: Not proposed owner';
    string constant internal ERROR_ALREADY_MANAGER      = 'Reason: Already manager';
    string constant internal ERROR_NOT_MANAGER          = 'Reason: Not manager';

    bool private stopped;
    address private owner;
    address private proposedOwner;
    mapping(address => bool) private managers;
    mapping(address => bool) private allowed;

    event Stopped();
    event Started();
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Manager(address indexed manager);
    event RemoveManager(address indexed manager);
    event Allowed(address indexed _address);
    event RemoveAllowed(address indexed _address);

    constructor () internal
    {
        stopped = false;
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    function getOwner() public view returns (address)
    {
        return owner;
    }

    modifier onlyOwner()
    {
        require(isOwner(), ERROR_NO_HAVE_PERMISSION);
        _;
    }

    modifier onlyAllowed()
    {
        require(isAllowed() || isOwner() || isManager(), ERROR_NO_HAVE_PERMISSION);
        _;
    }

    modifier onlyWhenNotStopped()
    {
        require(!isStopped(), ERROR_IS_STOPPED);
        _;
    }

    function isOwner() public view returns (bool)
    {
        return msg.sender == owner;
    }

    function isManager() public view returns (bool)
    {
        return managers[msg.sender];
    }

    function isAllowed() public view returns (bool)
    {
        return allowed[msg.sender];
    }

    function setManager(address _target) external onlyOwner returns (bool)
    {
        require(!managers[_target], ERROR_ALREADY_MANAGER);
        managers[_target] = true;

        emit Manager(_target);

        return true;
    }

    function removeManager(address _target) external onlyOwner returns (bool)
    {
        require(managers[_target], ERROR_NOT_MANAGER);
        managers[_target] = false;

        emit RemoveManager(_target);

        return true;
    }

    function allow(address _target) external onlyOwner returns (bool)
    {
        allowed[_target] = true;
        emit Allowed(_target);
        return true;
    }

    function removeAllowed(address _target) external onlyOwner returns (bool)
    {
        allowed[_target] = false;
        emit RemoveAllowed(_target);
        return true;
    }

    function isStopped() public view returns (bool)
    {
        if(isOwner() || isManager() || isAllowed())
        {
            return false;
        }
        else
        {
            return stopped;
        }
    }

    function stop() public onlyOwner
    {
        _stop();
    }

    function start() public onlyOwner
    {
        _start();
    }

    function proposeOwner(address _proposedOwner) public onlyOwner
    {
        require(msg.sender != _proposedOwner, ERROR_CALLER_ALREADY_OWNER);
        proposedOwner = _proposedOwner;
    }

    function claimOwnership() public
    {
        require(msg.sender == proposedOwner, ERROR_NOT_PROPOSED_OWNER);

        emit OwnershipTransferred(owner, proposedOwner);

        owner = proposedOwner;
        proposedOwner = address(0);
    }

    function _stop() internal
    {
        emit Stopped();
        stopped = true;
    }

    function _start() internal
    {
        emit Started();
        stopped = false;
    }
}

// 이 컨트랙트 주소에 approve를 먼저 해두고
contract NestreeExchange is Ownable
{
    using SafeMath for uint256;

    struct Exchange
    {
        address requestAddress; // 보내는 사람의 지갑 주소
        address receiveAddress; // 받는 사람의 지갑 주소
        address requestAssetAddress; // 보내는 사람이 받는 사람에게 보낼 자산 주소 만약 없다면 이더리웅이다.
        address receiveAssetAddress; // 받는 사람이 보내는 사람에게 보낼 자산 주소 만약 없다면 이더리움이다.
        uint256 requestAssetAmount; // 보내는 사람이 받는 사람에게 보낼 자산 수량
        uint256 receiveAssetAmount; // 받는 사람이 보내는 사람에게 보낼 자산 수량
    }

    mapping(address => bool) private allowedTokens;
    mapping(address => mapping(address => Exchange)) private exchanges;
    mapping(address => uint256) private ethBalances;

    event Ready(address indexed _requestAddress, address _requestAssetAddress, uint256 _requestAssetAmount, address indexed _receiveAddress, address _receiveAssetAddress, uint256 _receiveAssetAmount);

    function depoist() external payable returns(bool)
    {
        ethBalances[msg.sender] = ethBalances[msg.sender].add(msg.value);
    }

    function exchange(address payable _requestAddress, address _requestAssetAddress, uint256 _requestAssetAmount, address payable _receiveAddress, address _receiveAssetAddress, uint256 _receiveAssetAmount) external onlyWhenNotStopped returns (bool)
    {
        require(_requestAddress != address(0));
        require(_receiveAddress != address(0));
        require(_requestAssetAmount > 0);
        require(_receiveAssetAmount > 0);
        require(_requestAddress != _receiveAddress);
        require(_requestAssetAddress != _receiveAssetAddress);

        address _self = address(this);

        Exchange memory data = exchanges[_requestAddress][_receiveAddress];
        if(data.requestAddress != address(0) && data.receiveAddress != address(0))
        {
            require(data.requestAddress == _requestAddress);
            require(data.receiveAddress == _receiveAddress);
            require(data.requestAssetAddress == _requestAssetAddress);
            require(data.receiveAssetAddress == _receiveAssetAddress);
            require(data.requestAssetAmount == _requestAssetAmount);
            require(data.receiveAssetAmount == _receiveAssetAmount);

            if(_requestAssetAddress != address(0))
            {
                ERC20 requestAsset = ERC20(_requestAssetAddress);
                require(requestAsset.allowance(_requestAddress, _self) >= _requestAssetAmount);

                if(_receiveAssetAddress != address(0))
                {
                    ERC20 receiveAsset = ERC20(_receiveAssetAddress);
                    require(receiveAsset.allowance(_receiveAddress, _self) >= _receiveAssetAmount);

                    // 교환
                    requestAsset.transferFrom(_requestAddress, _receiveAddress, _requestAssetAmount);
                    receiveAsset.transferFrom(_receiveAddress, _requestAddress, _receiveAssetAmount);
                }
                else
                {
                    // receiver가 requester에게 eth를 보내는 경우

                    require(ethBalances[_receiveAddress] >= _receiveAssetAmount);

                    _requestAddress.transfer(_receiveAssetAmount); // receiver -> requester send eth
                    requestAsset.transferFrom(_requestAddress, _receiveAddress, _requestAssetAmount); // requester -> receiver send token
                }
            }
            else
            {
                // 이더 체크

                if(_receiveAssetAddress != address(0))
                {
                    ERC20 receiveAsset = ERC20(_receiveAssetAddress);
                    require(receiveAsset.allowance(_receiveAddress, _self) >= _receiveAssetAmount);

                    // 교환
                }
                else
                {
                    // 이더 체크 교환
                }
            }
        }
        else
        {
            exchanges[_requestAddress][_receiveAddress] = Exchange(_requestAddress, _receiveAddress, _requestAssetAddress, _receiveAssetAddress, _requestAssetAmount, _receiveAssetAmount);

            emit Ready(_requestAddress, _requestAssetAddress, _requestAssetAmount, _receiveAddress, _receiveAssetAddress, _receiveAssetAmount);
        }

        return true;
    }

}