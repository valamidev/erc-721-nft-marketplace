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
    const [owner, otherAccount, account3] = await ethers.getSigners();

    const Marketplace = await ethers.getContractFactory(
      "RarityHeadMarketplace"
    );
    const marketplace = await Marketplace.deploy(10);

    return { marketplace, owner, otherAccount };
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
      const { marketplace, owner, otherAccount } = await loadFixture(
        deployContract
      );

      await expect(
        marketplace.connect(owner).setFeeAddress(otherAccount.address)
      ).to.empty;

      await expect(
        marketplace.connect(otherAccount).setFeeAddress(owner.address)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });
});
