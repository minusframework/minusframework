import React from 'react';
import Layout from '@theme/Layout';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';

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
          <p className="hero__subtitle">{siteConfig.tagline}</p>
          <div className="hero__cta">
            <Link className="button button--lg button--primary" to="/docs/getting-started">
              Começar agora →
            </Link>
            <Link className="button button--lg button--secondary" to="/pricing">
              Ver planos
            </Link>
          </div>
        </section>
      </main>
    </Layout>
  );
}
