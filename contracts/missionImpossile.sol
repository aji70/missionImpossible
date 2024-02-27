// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// 0x5fbdb2315678afecb367f032d93f642f64180aa3;
// 0xe7f1725e7734ce288f8367e1bb143e90bb3f0512;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Ajidokwu is ERC721, ERC721URIStorage, Ownable {
    uint256 private _nextTokenId;

   constructor(address initialOwner, string memory _name, string memory _symbol)
    ERC721(_name, _symbol)
    Ownable(initialOwner)
{}


    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // The following functions are overrides required by Solidity.

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

contract AjidokwuFactory {
    mapping(address => address[]) public userContracts;
    Ajidokwu [] ajidokwu;
    mapping(address => address) useraddr;

    event NftCreated(address indexed owner, address indexed contractAddress);

    function createAjidokwuNFT(address _initialOwner, string memory _name, string memory _symbol) external {
        Ajidokwu newContract = new Ajidokwu(_initialOwner, _name, _symbol);
        userContracts[msg.sender].push(address(newContract));
        ajidokwu.push(newContract);
        emit NftCreated(msg.sender, address(newContract));
    }

    function getUserContracts() public view returns (address[] memory) {
        return userContracts[msg.sender];
    }
     function mints(uint256 _contractIndex, address _owner, string memory _tokenURI) external {
        require(_contractIndex < ajidokwu.length, "Invalid contract index");
        Ajidokwu nftContract = Ajidokwu(useraddr[msg.sender]);
        nftContract.safeMint(_owner, _tokenURI);
    }
  function mintNFT(uint256 _contractIndex, address _owner, string memory _tokenURI) external {
        require(_contractIndex < ajidokwu.length, "Invalid contract index");
        Ajidokwu nftContract = Ajidokwu(ajidokwu[_contractIndex]);
        nftContract.safeMint(_owner, _tokenURI);
    }
 
}

interface IAjidokwuFactory {
    function createAjidokwuNFT(address _initialOwner, string memory _name, string memory _symbol) external ;
   
     function getUserContracts() external view returns (address[] memory);
 function mints(uint256 _contractIndex, address _owner, string memory _tokenURI) external ;
}


contract SocialMedia {

  address owner = msg.sender;
    IAjidokwuFactory ajidokwuFactory = IAjidokwuFactory(0x26b989b9525Bb775C8DEDf70FeE40C36B397CE67); // Replace 0x123... with the actual address of the factory contract
    struct User {
        uint id;
        string username;
        string bio;
        string profilePicture;
        address[] followers;
        address[] following;
        bool isAdmin;
        address[] nft;
      
    }

    struct Group {
    string name;
    address[] members;
    // mapping(uint256 => NFTMetadata) nfts;
}

    uint userid;

    User[] usersArray;  
    mapping(address => mapping (address => bool)) isFollowing;
    mapping(address => User) public users;
    mapping(address => mapping(uint256 => string)) public userPosts;
    mapping(uint256 => address) public postOwner;
    mapping(uint256 => uint256) public postLikes;
    mapping(uint256 => mapping(uint256 => string)) public postComments;
    mapping(address => bool) hasRegistered;
    mapping (address => address) useraddr;
    
    uint256 public postCount;

    function registerUser(string memory _username, string memory _bio, string memory _profilePicture, string memory _TokeName, string memory _tokenSymbol) public returns (address[] memory)  {
        require(bytes(_username).length > 0, "Username cannot be empty");
        require(msg.sender != address(0), "Address zero detected");
        require(!hasRegistered[msg.sender], "Have already registered");
        uint _id = userid +1;
        hasRegistered[msg.sender] = true;
        
        ajidokwuFactory.createAjidokwuNFT( msg.sender, _TokeName,  _tokenSymbol);
        address[] memory nftAddress =  ajidokwuFactory.getUserContracts();
        
        users[msg.sender] = User(_id, _username, _bio, _profilePicture, new address[](0), new address[](0), false, nftAddress);
        userid++;
        useraddr[msg.sender] = nftAddress[0];
        return(nftAddress);
    }

     function registerAdmin(address _newAdmin) public {
        onlyOwner();
        require(hasRegistered[_newAdmin], "Not a  registered user");
        hasRegistered[_newAdmin] = true;
        User storage  newAdmin = users[_newAdmin];
        newAdmin.isAdmin = true;

    }

    function createPost(string memory _content, string memory tokenUri) public {
       IAjidokwuFactory ajidokwu = IAjidokwuFactory(useraddr[msg.sender]); // Replace 0x123... with the actual address of the factory contract
      require(msg.sender != address(0), "Address zero detected");
      require(hasRegistered[msg.sender], "Register to be able to create post");

        userPosts[msg.sender][postCount] = _content;
        postOwner[postCount] = msg.sender;
        postCount++;
        ajidokwu.mints(1, msg.sender, tokenUri);
    
    }

    function likePost(uint256 _postId) public {
        require(postOwner[_postId] != address(0), "Post does not exist");
        require(hasRegistered[msg.sender], "Register to be able to like post");
        postLikes[_postId]++;
    }

    function commentOnPost(uint256 _postId, string memory _comment) public {
        require(postOwner[_postId] != address(0), "Post does not exist");
        require(hasRegistered[msg.sender], "Register to be able to comment on post");
        postComments[_postId][postLikes[_postId]] = _comment;
        postLikes[_postId]++;
    }

    function followUser(address _userToFollow) public {
        require(bytes(users[_userToFollow].username).length > 0, "User not registered");
        require(!isFollowing[msg.sender][_userToFollow], "Already following");

        users[msg.sender].following.push(_userToFollow);
        isFollowing[msg.sender][_userToFollow] = true;

        users[_userToFollow].followers.push(msg.sender);
    }

    function getFeed() public view returns (string[] memory) {
        string[] memory feed = new string[](postCount);
        uint256 feedIndex = 0;
        for (uint256 i = 0; i < users[msg.sender].following.length; i++) {
            address user = users[msg.sender].following[i];
            for (uint256 j = 0; j < postCount; j++) {
                if (postOwner[j] == user) {
                    feed[feedIndex] = userPosts[user][j];
                    feedIndex++;
                }
            }
        }
        return feed;
    }


    function onlyOwner() private  view {
      require(msg.sender == owner, "only owner can perform action");
    }
}
