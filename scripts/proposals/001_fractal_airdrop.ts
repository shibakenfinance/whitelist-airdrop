import { ethers } from "hardhat";
import { FractalGovernance, SBXToken } from "../../typechain-types";

async function main() {
    // The proposal: A fractal airdrop distribution
    // Each recipient becomes a node in an expanding network
    // The more they engage, the more branches they create

    const fractals = [
        {
            name: "Genesis Fractal",
            allocation: ethers.utils.parseEther("1000000"), // 1M tokens
            duration: 30 * 24 * 60 * 60, // 30 days
            branches: 8, // Number of sub-distributions
            description: `
                In the realm of infinite scale
                Where blockchain meets poetic tale
                We propose a fractal distribution
                Each holder a star in our constellation

                Phase 1: Genesis Distribution
                - 1,000,000 SBX tokens
                - 30 days duration
                - 8 fractal branches

                Criteria:
                1. Early community members
                2. Content creators
                3. Technical contributors
                4. Ecosystem builders
                5. Liquidity providers
                6. Governance participants
                7. Social engagement leaders
                8. Cross-chain ambassadors

                Each branch will create its own micro-economy
                Growing the network in a self-similar pattern
                As above, so below
                The fractal nature of value flows
            `
        }
    ];

    // Get contract instances
    const governance = await ethers.getContract<FractalGovernance>("FractalGovernance");
    const sbxToken = await ethers.getContract<SBXToken>("SBXToken");

    // Prepare proposal data
    const description = fractals[0].description;
    const encodedFunctionCall = sbxToken.interface.encodeFunctionData(
        "mint",
        [governance.address, fractals[0].allocation]
    );

    // Create proposal
    const proposeTx = await governance.propose(
        [sbxToken.address],
        [0],
        [encodedFunctionCall],
        description
    );

    const receipt = await proposeTx.wait();
    console.log(`Proposal created with tx hash: ${receipt.transactionHash}`);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
