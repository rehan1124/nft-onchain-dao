import {
  CryptoDevsDAOABI,
  CryptoDevsDAOAddress,
  CryptoDevsNFTABI,
  CryptoDevsNFTAddress,
} from "../smart-contract-constants";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import Head from "next/head";
import { useEffect, useState } from "react";
import { formatEther } from "viem/utils";
import { useAccount, useBalance, useContractRead } from "wagmi";
import { readContract, waitForTransaction, writeContract } from "wagmi/actions";
import styles from "../styles/Home.module.css";
import { Inter } from "next/font/google";

const inter = Inter({
  subsets: ["latin"],
  display: "swap",
});

export default function Home() {
  // User wallet address and if it's connected
  const { address, isConnected } = useAccount();

  // Check if component is mounted
  const [isMounted, setIsMounted] = useState(false);

  // State for transaction is loading
  const [loading, setLoading] = useState(false);

  // Fake NFT Token ID to be purchased through DAO
  const [fakeNftTokenId, setFakeNftTokenId] = useState("");

  // Storing proposals
  const [proposals, setProposals] = useState([]);

  // State variable to switch between the 'Create Proposal' and 'View Proposals' tabs
  const [selectedTab, setSelectedTab] = useState("");

  // Get DAOs balance
  const daoBalance = useBalance({ address: CryptoDevsDAOAddress });

  // Check number of proposals created in DAO
  const countProposalsInDao = useContractRead({
    abi: CryptoDevsDAOABI,
    address: CryptoDevsDAOAddress,
    functionName: "numberOfProposalsMade",
  });

  // Read NFT balance of the user
  const nftBalanceOfUser = useContractRead({
    abi: CryptoDevsNFTABI,
    address: CryptoDevsNFTAddress,
    functionName: "",
    args: [address],
  });

  async function createProposal() {
    setLoading(true);

    try {
      const tx = await writeContract({
        address: CryptoDevsDAOAddress,
        abi: CryptoDevsDAOABI,
        functionName: "createProposal",
        args: [fakeNftTokenId],
      });

      await waitForTransaction(tx);
    } catch (error) {
      console.error(error);
      window.alert(error);
    }

    setLoading(false);
  }
}
