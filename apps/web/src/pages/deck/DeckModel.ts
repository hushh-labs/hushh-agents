/* ── Deck Model ── Pure data types ── */

export interface DeckAgent {
  id: string;
  name: string;
  category: string;
  rating: number;
  reviewCount: number;
  city: string;
  state: string;
  address: string;
  phone: string;
  photoUrl: string;
  services: string[];
  bio: string;
  website: string | null;
  hours: string | null;
  yearEstablished: number | null;
  specialties: string | null;
  representative: { name: string; role: string; bio: string } | null;
  locallyOwned: boolean;
  certified: boolean;
  messagingEnabled: boolean;
  messagingText: string | null;
  responseTime: string | null;
}

export type SwipeAction = "save" | "pass" | "view";

export interface DeckState {
  agents: DeckAgent[];
  currentIndex: number;
  loading: boolean;
  error: string | null;
  animatingDirection: "left" | "right" | null;
}
