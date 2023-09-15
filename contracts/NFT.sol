// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NFT is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public nextTokenId = 1;
    uint256 public maxSupply = 50;
    uint256 public mintingPrice = 0.01 ether;
    string private baseURI =
        "ipfs://QmeRsttzmYHKyXQA6edTPSUaZNYX6Zmurc8a9jUh1GCpf1/";

    mapping(address => bool) public whitelist;
    bool public mintingPaused = false;

    event Minted(address indexed to, uint256 indexed tokenId);
    event MintingPriceUpdated(uint256 newPrice);
    event MintingPaused(bool paused);
    event AdminChanged(address indexed newAdmin);
    event CryptoWithdrawn(uint256 amount);

    constructor() ERC721("Pandas Roly-Poly", "PRP") {}

    modifier mintingNotPaused() {
        require(!mintingPaused, "Minting is paused");
        _;
    }

    modifier belowMaxSupply(uint256 count) {
        require(totalSupply() + count <= maxSupply, "You reached max supply");
        _;
    }

    function mint() external payable mintingNotPaused belowMaxSupply(1) {
        require(msg.value == mintingPrice, "Incorrect price");

        uint256 tokenId = nextTokenId;
        _safeMint(msg.sender, tokenId);
        nextTokenId++;

        emit Minted(msg.sender, tokenId);
    }

    function freeMint() external mintingNotPaused belowMaxSupply(1) {
        require(whitelist[msg.sender] || msg.sender == owner(), "No rights");

        uint256 tokenId = nextTokenId;
        _safeMint(msg.sender, tokenId);
        nextTokenId++;

        emit Minted(msg.sender, tokenId);
    }

    function adminMint(
        address to,
        uint256 count
    ) external onlyOwner belowMaxSupply(count) {
        for (uint256 i = 0; i < count; i++) {
            uint256 tokenId = nextTokenId;
            _safeMint(to, tokenId);
            nextTokenId++;
            emit Minted(to, tokenId);
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory base = _baseURI();
        return
            bytes(base).length > 0
                ? string(abi.encodePacked(base, tokenId.toString(), ".json"))
                : "";
    }

    function addToWhitelist(address _address) external onlyOwner {
        whitelist[_address] = true;
    }

    function removeFromWhitelist(address _address) external onlyOwner {
        whitelist[_address] = false;
    }

    function updateMintingPrice(uint256 _newPrice) external onlyOwner {
        mintingPrice = _newPrice;
        emit MintingPriceUpdated(_newPrice);
    }

    function pauseMinting() external onlyOwner {
        mintingPaused = true;
        emit MintingPaused(true);
    }

    function resumeMinting() external onlyOwner {
        mintingPaused = false;
        emit MintingPaused(false);
    }

    function changeAdmin(address _newAdmin) external onlyOwner {
        transferOwnership(_newAdmin);
        emit AdminChanged(_newAdmin);
    }

    function withdrawCrypto(uint256 _amount) external onlyOwner {
        require(_amount <= address(this).balance, "Insufficient balance");
        payable(owner()).transfer(_amount);
        emit CryptoWithdrawn(_amount);
    }
}
