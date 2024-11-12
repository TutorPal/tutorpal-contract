// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDecentralizedProfiles {
    enum RoleType {
        Student,
        Tutor
    }

    struct User {
        string displayName;
        RoleType roleType;
        bool isRegistered;
    }

    event UserRegister(address indexed user, string displayName, RoleType roleType);

    // Function to register a new user
    function registerUser(string calldata _displayName, RoleType _roleType) external;

    // Function to get user profile
    function getUserProfile(address _user)
        external
        view
        returns (string memory displayName, RoleType roleType, bool isRegistered);
}
