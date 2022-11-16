import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

describe.only("Marketplace", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployContract() {
    // Contracts are deployed using the first signer/account by default
    const [owner, account1, account2] = await ethers.getSigners();

    const Marketplace = await ethers.getContractFactory(
      "RarityHeadMarketplace"
    );

    const marketplace = await Marketplace.deploy(10);

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

      expect(await marketplace.feePercent()).to.equal(10);
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
});
