import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

describe.only("Marketplace", function () {
  async function advanceBlockTo(blockNumber: number) {
    for (let i = await ethers.provider.getBlockNumber(); i < blockNumber; i++) {
      await advanceBlock();
    }
  }

  async function _hash(
    tokenAddress: string,
    id: number,
    ownerAddress: string,
    blocknumber?: number
  ) {
    let bn = await ethers.provider.getBlockNumber();

    let hash = await ethers.utils.solidityKeccak256(
      ["uint256", "address", "uint256", "address"],
      [blocknumber ?? bn, tokenAddress, id, ownerAddress]
    );
    return hash;
  }

  async function advanceBlock() {
    return ethers.provider.send("evm_mine", []);
  }

  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployContract() {
    // Contracts are deployed using the first signer/account by default
    const [owner, account1, account2] = await ethers.getSigners();

    const Marketplace = await ethers.getContractFactory(
      "RarityHeadMarketplace"
    );

    const marketplace = await Marketplace.deploy();

    const NFT = await ethers.getContractFactory("Token");

    const nftToken = await NFT.connect(owner).deploy();

    await nftToken.mint(owner.address, 0);
    await nftToken.mint(account1.address, 1);
    await nftToken.mint(account2.address, 11);
    await nftToken.mint(account2.address, 2);

    return { marketplace, nftToken, owner, account1, account2 };
  }

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      const { marketplace, owner } = await loadFixture(deployContract);

      expect(await marketplace.owner()).to.equal(owner.address);

      expect(await marketplace.feePercent()).to.equal(100);
      expect(await marketplace.extendOnBid()).to.equal(50);
    });
  });

  describe("Change Fee Address", function () {
    it("Should set fee address", async function () {
      const { marketplace, owner, account1 } = await loadFixture(
        deployContract
      );

      await expect(marketplace.connect(owner).setFeeAddress(account1.address))
        .to.empty;

      await expect(
        marketplace.connect(account1).setFeeAddress(owner.address)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });

  describe("Create listing", function () {
    it("Create Auction Listing", async function () {
      const { marketplace, nftToken, owner, account1, account2 } =
        await loadFixture(deployContract);

      await nftToken.connect(account1).approve(marketplace.address, 1);
      await nftToken.connect(account2).approve(marketplace.address, 11);

      await marketplace
        .connect(account1)
        .fixedPrice(nftToken.address, 1, 50, 350);

      const hash1 = _hash(nftToken.address, 1, account1.address, 9);

      await marketplace
        .connect(account2)
        .fixedPrice(nftToken.address, 11, 50, 350);

      const hash2 = _hash(nftToken.address, 11, account2.address, 10);

      const getOrder1 = await marketplace.orderInfo(hash1);
      const getOrder2 = await marketplace.orderInfo(hash2);

      expect(getOrder1.orderType).to.equal(0);
      expect(getOrder2.orderType).to.equal(0);

      expect(getOrder1.seller).to.equal(account1.address);
      expect(getOrder2.seller).to.equal(account2.address);
    });
  });

  describe("Buy / Win auction", function () {
    it("Buy / Win auction", async function () {
      const { marketplace, nftToken, owner, account1, account2 } =
        await loadFixture(deployContract);

      // Get listed
      await nftToken.connect(account1).approve(marketplace.address, 1);

      await marketplace
        .connect(account1)
        .auction(nftToken.address, 1, 10 ** 5, 350);

      const orderHash = _hash(nftToken.address, 1, account1.address, 8);

      const getOrderListed = await marketplace.orderInfo(orderHash);

      expect(getOrderListed.orderType).to.equal(1);

      expect(getOrderListed.seller).to.equal(account1.address);

      // Create bid as buyer
      await expect(
        marketplace.connect(account2).bid(orderHash, { value: 1 })
      ).to.be.revertedWith("low price bid");

      await marketplace.connect(account2).bid(orderHash, { value: 10 ** 5 });

      await expect(
        marketplace.connect(account2).claim(orderHash)
      ).to.be.revertedWith("Auction has not ended");

      await expect(
        marketplace.connect(account2).bid(orderHash, { value: 10 ** 5 + 1 })
      ).to.be.revertedWith("low price bid");

      await marketplace.connect(account2).bid(orderHash, { value: 10 ** 6 });

      const getOrderAfterBid = await marketplace.orderInfo(orderHash);

      expect(getOrderAfterBid.orderType).to.equal(1);
      expect(getOrderAfterBid.lastBidPrice).to.equal(10 ** 6);

      // Claim as winner

      await advanceBlockTo(351);

      const balanceBeforeClaim = await account1.getBalance();

      await marketplace.connect(account2).claim(orderHash);

      await expect(
        marketplace.connect(account2).claim(orderHash)
      ).to.be.revertedWith("Already sold");

      const getOrderAfterExpire = await marketplace.orderInfo(orderHash);

      const balanceAfterClaim = await account1.getBalance();

      expect(getOrderAfterExpire.isSold).to.equal(true);
      expect(getOrderAfterExpire.lastBidPrice).to.equal(10 ** 6);
      expect(balanceAfterClaim.sub(balanceBeforeClaim)).to.equal(
        10 ** 6 * 0.99
      );
    });
  });

  describe("Cancel auction", function () {
    it("Cancel auction", async function () {
      const { marketplace, nftToken, owner, account1, account2 } =
        await loadFixture(deployContract);

      // Get listed
      await nftToken.connect(account1).approve(marketplace.address, 1);

      await marketplace.connect(account1).auction(nftToken.address, 1, 50, 350);

      const orderHash = _hash(nftToken.address, 1, account1.address, 8);

      await marketplace.connect(account1).cancelOrder(orderHash);

      const getOrderAfterCancel = await marketplace.orderInfo(orderHash);

      expect(getOrderAfterCancel.isSold).to.equal(false);
      expect(getOrderAfterCancel.isCancelled).to.equal(true);
    });
  });

  describe("Royalty Fees", function () {
    it("Deduct Royalty fee", async function () {
      const { marketplace, nftToken, owner, account1, account2 } =
        await loadFixture(deployContract);

      // Get listed
      await nftToken.connect(account1).approve(marketplace.address, 1);

      await marketplace
        .connect(account1)
        .fixedPrice(nftToken.address, 1, 10 ** 5, 350);

      const orderHash = _hash(nftToken.address, 1, account1.address, 8);

      await marketplace.connect(owner).setRoyaltyFee(nftToken.address, 900);

      const balanceBeforeBuy = await account1.getBalance();

      await marketplace.connect(account2).buy(orderHash, { value: 10 ** 5 });

      const balanceAfterBuy = await account1.getBalance();

      expect(balanceAfterBuy.sub(balanceBeforeBuy)).to.equal(10 ** 5 * 0.9);
    });
  });

  describe("Fees can be disabled", function () {
    it("Disabled fee", async function () {
      const { marketplace, nftToken, owner, account1, account2 } =
        await loadFixture(deployContract);

      // Get listed
      await nftToken.connect(account1).approve(marketplace.address, 1);

      await marketplace
        .connect(account1)
        .fixedPrice(nftToken.address, 1, 10 ** 5, 350);

      const orderHash = _hash(nftToken.address, 1, account1.address, 8);

      await marketplace.connect(owner).setRoyaltyFee(nftToken.address, 0);
      await marketplace.connect(owner).updateFeePercent(0);

      const balanceBeforeBuy = await account1.getBalance();

      await marketplace.connect(account2).buy(orderHash, { value: 10 ** 5 });

      const balanceAfterBuy = await account1.getBalance();

      expect(balanceAfterBuy.sub(balanceBeforeBuy)).to.equal(10 ** 5);
    });
  });
});
