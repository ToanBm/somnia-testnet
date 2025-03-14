# Create Your Next.js Project
npx create-next-app my-dapp-ui

# Setting Up a React Context for Global State
cd my-dapp-ui
mkdir src/contexts

cat <<'EOF' > src/contexts/walletcontext.js
import { createContext, useContext, useState } from "react";

const WalletContext = createContext();

export function WalletProvider({ children }) {
  const [connected, setConnected] = useState(false);
  const [address, setAddress] = useState("");
  
  async function connectToMetaMask() {
    if (typeof window !== "undefined" && window.ethereum) {
      try {
        await window.ethereum.request({ method: "eth_requestAccounts" });
        // For simplicity, get the first address
        const [userAddress] = window.ethereum.selectedAddress
          ? [window.ethereum.selectedAddress]
          : [];
        setAddress(userAddress);
         setConnected(true);
      } catch (err) {
        console.error("User denied account access:", err);
      }
    } else {
      console.log("MetaMask is not installed!");
    }
  }

  function disconnectWallet() {
    setConnected(false);
    setAddress("");
  }

  // Return the context provider
  return (
<WalletContext.Provider
      value={{
        connected,
        address,
        connectToMetaMask,
        disconnectWallet,
      }}
    >
      {children}
    </WalletContext.Provider>
  );
}


export function useWallet() {
  return useContext(WalletContext);
}
EOF

# Creating a Global NavBar in _app.js
rm src/pages/_app.js

cat <<'EOF' > src/pages/_app.js
import "../styles/globals.css";
import { WalletProvider } from "../contexts/walletcontext";
import NavBar from "../components/navbar";

function MyApp({ Component, pageProps }) {
  return (
    <WalletProvider>
      <NavBar />
      <main className="pt-16">
        <Component {...pageProps} />
      </main>
    </WalletProvider>
  );
}

export default MyApp;
EOF

# NavBar
mkdir src/components

cat <<'EOF' > src/components/navbar.js
import { useWallet } from "../contexts/walletcontext";
import Link from "next/link";

export default function NavBar() {
  const { connected, address, disconnectWallet } = useWallet();


  return (
    <nav className="fixed w-full bg-white shadow z-50">
      <div className="mx-auto max-w-7xl px-4 flex h-16 items-center justify-between">
        <Link href="/">
          <h1 className="text-xl font-bold text-blue-600">MyDAO</h1>
        </Link>
<div>
          {connected ? (
            <div className="flex items-center space-x-4 text-blue-500">
              <span>{address.slice(0, 6)}...{address.slice(-4)}</span>
              <button onClick={disconnectWallet} className="px-4 py-2 bg-red-500 text-white rounded">
                Logout
              </button>
            </div>
          ) : (
            <span className="text-gray-500">Not connected</span>
          )}
        </div>
      </div>
    </nav>
  );
}
EOF

# Test Your Setup
npm run dev












