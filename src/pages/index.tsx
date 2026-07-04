import React from 'react';
import Layout from '@theme/Layout';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import HighlightCards from '../components/HighlightCards';
import ModuleGrid from '../components/ModuleGrid';

export default function Home(): React.ReactElement {
  const {siteConfig} = useDocusaurusContext();
  return (
    <Layout title="MinusFrameWork" description={siteConfig.tagline}>
      <main>
        <section className="hero">
          <h1 className="hero__title">
            Framework Delphi<br />
            <span style={{color: 'var(--ifm-color-primary)'}}>moderno e modular</span>
          </h1>
          <div className="hero__cta">
            <Link className="button button--lg button--primary" to="/docs/getting-started">
              Começar agora →
            </Link>
            <Link className="button button--lg button--secondary" to="/pricing">
              Ver planos
            </Link>
          </div>
        </section>

        <section className="container" style={{padding: '2rem 1rem'}}>
          <h2 style={{textAlign: 'center', marginBottom: '0.5rem'}}>Módulos gratuitos</h2>
          <p style={{textAlign: 'center', color: 'var(--ifm-color-emphasis-600)', marginBottom: '1.5rem'}}>
            Comece com esses módulos sem custo — licença MIT.
          </p>
          <HighlightCards />

          <h2 style={{textAlign: 'center', marginTop: '3rem', marginBottom: '0.5rem'}}>Ecossistema completo</h2>
          <p style={{textAlign: 'center', color: 'var(--ifm-color-emphasis-600)', marginBottom: '1.5rem'}}>
            Todos os módulos do MinusFrameWork, do Free ao Enterprise.
          </p>
          <ModuleGrid />
        </section>
      </main>
    </Layout>
  );
}
