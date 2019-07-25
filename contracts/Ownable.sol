pragma solidity ^0.5.10;

contract Ownable
{
    string constant internal ERROR_NO_HAVE_PERMISSION   = 'Reason: No have permission.';
    string constant internal ERROR_IS_STOPPED           = 'Reason: Is stopped.';
    string constant internal ERROR_ADDRESS_NOT_VALID    = 'Reason: Address is not valid.';
    string constant internal ERROR_CALLER_ALREADY_OWNER = 'Reason: Caller already is owner';
    string constant internal ERROR_CALLER_ALREADY_MASTER = 'Reason: Caller already is master';
    string constant internal ERROR_NOT_PROPOSED_OWNER   = 'Reason: Not proposed owner';
    string constant internal ERROR_NOT_PROPOSED_MASTER   = 'Reason: Not proposed master';
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