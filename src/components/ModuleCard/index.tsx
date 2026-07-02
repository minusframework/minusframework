import React from 'react';
import Link from '@docusaurus/Link';
import Badge from '../Badge';
import type {Tier} from '../Badge';

interface ModuleCardProps {
  name: string;
  description: string;
  tier: Tier;
  icon: string;
  iconBg: string;
  link: string;
}

const ICON_MAP: Record<string, string> = {
  database: '\u{1F5C4}',
  'arrow-up-bold-box': '\u{2B06}',
  console: '\u{2328}',
  'toggle-switch': '\u{1F500}',
  'message-flash': '\u{1F4E9}',
  puzzle: '\u{1F9E9}',
  'chart-timeline-variant': '\u{1F4CA}',
  robot: '\u{1F916}',
};

export default function ModuleCard({name, description, tier, icon, iconBg, link}: ModuleCardProps): React.ReactElement {
  return (
    <div className="module-card">
      <h3>
        <span className="module-icon" style={{background: iconBg}}>
          {ICON_MAP[icon] ?? '\u{1F4E6}'}
        </span>
        {name}
      </h3>
      <p>{description}</p>
      <Badge tier={tier} />
      <div style={{marginTop: '0.75rem'}}>
        <Link className="button button--sm button--primary" to={link}>
          Documentação →
        </Link>
      </div>
    </div>
  );
}
