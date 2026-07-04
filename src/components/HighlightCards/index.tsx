import React from 'react';
import Link from '@docusaurus/Link';

interface HighlightProps {
  title: string;
  description: string;
  link: string;
}

const HIGHLIGHTS: HighlightProps[] = [
  {
    title: 'MinusORM',
    description: 'ORM com RTTI, queries fluentes e Unit of Work. Suporte a SQLite no Free, 7 bancos no Pro.',
    link: '/docs/orm/',
  },
  {
    title: 'MinusMigrator',
    description: 'Migração versionada de schema via CLI, GUI e DLL. Diff automático entre versões.',
    link: '/docs/migrator/',
  },
  {
    title: 'MinusCLI',
    description: 'Scaffolding de entidades, APIs e projetos completos em segundos via terminal.',
    link: '/docs/cli/',
  },
];

export default function HighlightCards(): React.ReactElement {
  return (
    <div style={{display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '1rem', margin: '2rem 0', justifyContent: 'center'}}>
      {HIGHLIGHTS.map((h) => (
        <div key={h.title} className="card">
          <h3 style={{color: 'var(--ifm-color-primary)'}}>{h.title}</h3>
          <p>{h.description}</p>
          <Link className="button button--sm button--primary" to={h.link}>
            Documentação →
          </Link>
        </div>
      ))}
    </div>
  );
}
