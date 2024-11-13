// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IDecentralizedProfiles} from "../interfaces/IDecentralizedProfiles.sol";

abstract contract DecentralizedProfiles is IDecentralizedProfiles {
    mapping(address usersAddress => User users) users;
    /// @dev The set of addresses authorized as Admins
    mapping(address => uint256) public admins;

    constructor() {
        admins[msg.sender] = 1;
    }

    modifier onlyAdmin() {
        if (admins[msg.sender] != 1) revert NotAdmin();
        _;
    }

    modifier ValidInstructor() {
        require(users[msg.sender].roleType == RoleType.Instructor);
        _;
    }

    modifier ValidStudent() {
        require(users[msg.sender].roleType == RoleType.Student);
        _;
    }
    /**
     * @notice Registers a new user with a display name and role type.
     * @param _displayName The display name of the user.
     * @param _roleType The role type of the user (FabricSeller, Designer, Buyer).
     * @dev Emits an error if the user is already registered.
     */

    function registerUser(string memory _displayName, RoleType _roleType) external {
        require(users[msg.sender].isRegistered == false, NotANewUser(msg.sender));
        users[msg.sender] = User({
            displayName: _displayName,
            roleType: _roleType,
            isRegistered: true,
            registerationTime: block.timestamp
        });
        emit UserRegistered(msg.sender, _displayName, _roleType);
    }

    function getUserProfile(address _user)
        external
        view
        returns (string memory displayName, RoleType roleType, bool isRegistered)
    {
        User memory thisUser = users[_user];
        return (thisUser.displayName, thisUser.roleType, thisUser.isRegistered);
    }

    function isAdmin(address usr) external view returns (bool) {
        return admins[usr] == 1;
    }

    /// @notice Adds a new admin
    /// Can only be called by a current admin
    /// @param admin_ - The new admin
    function addAdmin(address admin_) external onlyAdmin {
        admins[admin_] = 1;
        emit NewAdmin(admin_, msg.sender);
    }

    /// @notice Removes an existing Admin
    /// Can only be called by a current admin
    /// @param admin - The admin to be removed
    function removeAdmin(address admin) external onlyAdmin {
        admins[admin] = 0;
        emit RemovedAdmin(admin, msg.sender);
    }
    /// @notice Removes the admin role for the caller
    /// Can only be called by an existing admin

    function renounceAdminRole() external onlyAdmin {
        admins[msg.sender] = 0;
        emit RemovedAdmin(msg.sender, msg.sender);
    }
}
