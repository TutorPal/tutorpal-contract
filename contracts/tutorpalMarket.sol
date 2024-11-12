//SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

contract TutorpalMarket {
    error NotANewUser(address userAddress);

    event UserRegistered(address indexed userAddress, string displayName, RoleType roleType);

    enum RoleType {
        NotRegitered,
        Student,
        Tutor
    }

    struct User {
        string displayName;
        RoleType roleType;
        bool isRegistered;
    }

    mapping(address usersAddress => User users) users;

    /**
     * @notice Registers a new user with a display name and role type.
     * @param _displayName The display name of the user.
     * @param _roleType The role type of the user (FabricSeller, Designer, Buyer).
     * @dev Emits an error if the user is already registered.
     */
    function registerUser(string memory _displayName, RoleType _roleType) external {
        require(users[msg.sender].isRegistered == false, NotANewUser(msg.sender));
        users[msg.sender] = User({displayName: _displayName, roleType: _roleType, isRegistered: true});
        emit UserRegistered(msg.sender, _displayName, _roleType);
    }

    //  /*//////////////////////////////////////////////////////////////
    //                         PAUSE
    //     //////////////////////////////////////////////////////////////*/

    //     /// @notice Pause trading on the Exchange
    //     function pauseTrading() external onlyAdmin {
    //         _pauseTrading();
    //     }

    //     /// @notice Unpause trading on the Exchange
    //     function unpauseTrading() external onlyAdmin {
    //         _unpauseTrading();
    //     }
}
