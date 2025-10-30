
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title VehicleOwnershipTransfer
 * @dev Smart contract for managing vehicle ownership transfers on blockchain
 */
contract VehicleOwnershipTransfer {
    
    struct Vehicle {
        string vin; // Vehicle Identification Number
        string make;
        string model;
        uint256 year;
        address currentOwner;
        address previousOwner;
        uint256 registrationDate;
        bool isRegistered;
        uint256 transferCount;
    }
    
    struct TransferRequest {
        address from;
        address to;
        string vin;
        uint256 requestTime;
        bool isApproved;
        bool isCompleted;
    }
    
    // Mappings
    mapping(string => Vehicle) public vehicles;
    mapping(address => string[]) public ownerVehicles;
    mapping(string => TransferRequest) public pendingTransfers;
    
    // Events
    event VehicleRegistered(string indexed vin, address indexed owner, uint256 timestamp);
    event TransferInitiated(string indexed vin, address indexed from, address indexed to, uint256 timestamp);
    event TransferCompleted(string indexed vin, address indexed from, address indexed to, uint256 timestamp);
    event TransferCancelled(string indexed vin, address indexed by, uint256 timestamp);
    
    // Modifiers
    modifier onlyVehicleOwner(string memory _vin) {
        require(vehicles[_vin].currentOwner == msg.sender, "Not the vehicle owner");
        _;
    }
    
    modifier vehicleExists(string memory _vin) {
        require(vehicles[_vin].isRegistered, "Vehicle not registered");
        _;
    }
    
    /**
     * @dev Register a new vehicle on the blockchain
     * @param _vin Vehicle Identification Number
     * @param _make Vehicle manufacturer
     * @param _model Vehicle model
     * @param _year Manufacturing year
     */
    function registerVehicle(
        string memory _vin,
        string memory _make,
        string memory _model,
        uint256 _year
    ) public {
        require(!vehicles[_vin].isRegistered, "Vehicle already registered");
        require(bytes(_vin).length > 0, "VIN cannot be empty");
        require(_year <= block.timestamp / 365 days + 1970, "Invalid year");
        
        vehicles[_vin] = Vehicle({
            vin: _vin,
            make: _make,
            model: _model,
            year: _year,
            currentOwner: msg.sender,
            previousOwner: address(0),
            registrationDate: block.timestamp,
            isRegistered: true,
            transferCount: 0
        });
        
        ownerVehicles[msg.sender].push(_vin);
        
        emit VehicleRegistered(_vin, msg.sender, block.timestamp);
    }
    
    /**
     * @dev Initiate a vehicle ownership transfer
     * @param _vin Vehicle Identification Number
     * @param _newOwner Address of the new owner
     */
    function initiateTransfer(string memory _vin, address _newOwner) 
        public 
        vehicleExists(_vin) 
        onlyVehicleOwner(_vin) 
    {
        require(_newOwner != address(0), "Invalid new owner address");
        require(_newOwner != msg.sender, "Cannot transfer to yourself");
        require(!pendingTransfers[_vin].isCompleted && 
                pendingTransfers[_vin].from == address(0), 
                "Transfer already pending");
        
        pendingTransfers[_vin] = TransferRequest({
            from: msg.sender,
            to: _newOwner,
            vin: _vin,
            requestTime: block.timestamp,
            isApproved: false,
            isCompleted: false
        });
        
        emit TransferInitiated(_vin, msg.sender, _newOwner, block.timestamp);
    }
    
    /**
     * @dev Complete the vehicle ownership transfer (called by new owner)
     * @param _vin Vehicle Identification Number
     */
    function completeTransfer(string memory _vin) 
        public 
        vehicleExists(_vin) 
    {
        TransferRequest storage transfer = pendingTransfers[_vin];
        
        require(transfer.to == msg.sender, "You are not the designated new owner");
        require(!transfer.isCompleted, "Transfer already completed");
        require(transfer.from != address(0), "No pending transfer found");
        
        // Update vehicle ownership
        Vehicle storage vehicle = vehicles[_vin];
        address previousOwner = vehicle.currentOwner;
        
        vehicle.previousOwner = previousOwner;
        vehicle.currentOwner = msg.sender;
        vehicle.transferCount++;
        
        // Update owner vehicle lists
        ownerVehicles[msg.sender].push(_vin);
        
        // Mark transfer as completed
        transfer.isApproved = true;
        transfer.isCompleted = true;
        
        emit TransferCompleted(_vin, previousOwner, msg.sender, block.timestamp);
    }
    
    /**
     * @dev Get vehicle details
     * @param _vin Vehicle Identification Number
     */
    function getVehicleDetails(string memory _vin) 
        public 
        view 
        vehicleExists(_vin) 
        returns (
            string memory make,
            string memory model,
            uint256 year,
            address currentOwner,
            address previousOwner,
            uint256 registrationDate,
            uint256 transferCount
        ) 
    {
        Vehicle memory vehicle = vehicles[_vin];
        return (
            vehicle.make,
            vehicle.model,
            vehicle.year,
            vehicle.currentOwner,
            vehicle.previousOwner,
            vehicle.registrationDate,
            vehicle.transferCount
        );
    }
    
    /**
     * @dev Get all vehicles owned by an address
     * @param _owner Address of the owner
     */
    function getOwnerVehicles(address _owner) 
        public 
        view 
        returns (string[] memory) 
    {
        return ownerVehicles[_owner];
    }
    
    /**
     * @dev Cancel a pending transfer (only by current owner)
     * @param _vin Vehicle Identification Number
     */
    function cancelTransfer(string memory _vin) 
        public 
        vehicleExists(_vin) 
        onlyVehicleOwner(_vin) 
    {
        TransferRequest storage transfer = pendingTransfers[_vin];
        require(!transfer.isCompleted, "Transfer already completed");
        require(transfer.from == msg.sender, "No pending transfer from you");
        
        delete pendingTransfers[_vin];
        
        emit TransferCancelled(_vin, msg.sender, block.timestamp);
    }
    
    /**
     * @dev Get pending transfer details
     * @param _vin Vehicle Identification Number
     */
    function getPendingTransfer(string memory _vin) 
        public 
        view 
        returns (
            address from,
            address to,
            uint256 requestTime,
            bool isCompleted
        ) 
    {
        TransferRequest memory transfer = pendingTransfers[_vin];
        return (
            transfer.from,
            transfer.to,
            transfer.requestTime,
            transfer.isCompleted
        );
    }
}