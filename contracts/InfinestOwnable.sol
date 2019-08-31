pragma solidity ^0.5.11;

contract InfinestOwnable
{
    string constant internal ERROR_NO_HAVE_PERMISSION   = 'Reason: No have permission.';
    string constant internal ERROR_IS_STOPPED           = 'Reason: Is stopped.';
    string constant internal ERROR_CALLER_ALREADY_OWNER = 'Reason: Caller already is owner';
    string constant internal ERROR_NOT_PROPOSED_OWNER   = 'Reason: Not proposed owner';
    string constant internal ERROR_ALREADY_MANAGER      = 'Reason: Already manager';
    string constant internal ERROR_NOT_MANAGER          = 'Reason: Not manager';

    bool private stopped;
    address private owner;
    address private proposedOwner;
    address private subOwner;
    mapping(address => bool) private managers;

    event Stopped();
    event Started();
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SetSubOwner(address indexed subOwner);
    event Manager(address indexed manager);
    event RemoveManager(address indexed manager);

    constructor () internal
    {
        stopped = false;
        owner = msg.sender;
        subOwner = msg.sender;
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

    modifier hasPermission()
    {
        require(isOwner() || isManager(), ERROR_NO_HAVE_PERMISSION);
        _;
    }

    modifier onlyWhenNotStopped()
    {
        require(!isStopped(), ERROR_IS_STOPPED);
        _;
    }

    function isOwner() public view returns (bool)
    {
        return msg.sender == owner || msg.sender == subOwner;
    }

    function isManager() public view returns (bool)
    {
        return managers[msg.sender];
    }

    function setSubOwner(address _target) external onlyOwner
    {
        require(_target != address(0), 'Reason: Invliad adddres of target');
        subOwner = _target;
        emit SetSubOwner(subOwner);
    }

    function setManager(address _target) external onlyOwner
    {
        require(!managers[_target], ERROR_ALREADY_MANAGER);
        managers[_target] = true;

        emit Manager(_target);
    }

    function removeManager(address _target) external onlyOwner
    {
        require(managers[_target], ERROR_NOT_MANAGER);
        managers[_target] = false;

        emit RemoveManager(_target);
    }

    function isStopped() public view returns (bool)
    {
        if(isOwner() || isManager())
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

    function promoteOwnership() public onlyOwner
    {
        require(msg.sender != owner, ERROR_CALLER_ALREADY_OWNER);

        emit OwnershipTransferred(owner, subOwner);

        owner = subOwner;
        subOwner = address(0);
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