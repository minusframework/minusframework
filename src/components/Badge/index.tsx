import React from 'react';

export type Tier = 'free' | 'pro' | 'enterprise';

interface BadgeProps {
  tier: Tier;
  label?: string;
}

const TIER_CLASS: Record<Tier, string> = {
  free: 'badge-free',
  pro: 'badge-pro',
  enterprise: 'badge-enterprise',
};

const TIER_LABEL: Record<Tier, string> = {
  free: 'Free',
  pro: 'Pro',
  enterprise: 'Enterprise',
};

export default function Badge({ tier, label }: BadgeProps): React.ReactElement {
  return <span className={`badge ${TIER_CLASS[tier]}`}>{label ?? TIER_LABEL[tier]}</span>;
}
