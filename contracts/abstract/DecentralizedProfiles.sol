// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IDecentralizedProfiles} from "../interfaces/IDecentralizedProfiles.sol";

abstract contract DecentralizedProfiles is IDecentralizedProfiles {
    mapping(address usersAddress => User users) users;

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
}
