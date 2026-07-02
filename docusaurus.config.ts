import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

const config: Config = {
  title: 'MinusFrameWork',
  tagline: 'Framework Delphi completo — ORM, Migrator, Mensageria, Feature Flags, Telemetria e IA',
  favicon: 'img/favicon.ico',

  future: {
    v4: true,
  },

  url: 'https://gabrielferreiramendes.github.io',
  baseUrl: '/minusframework/',

  organizationName: 'GabrielFerreiraMendes',
  projectName: 'minusframework',

  onBrokenLinks: 'warn',
  onBrokenMarkdownLinks: 'warn',

  i18n: {
    defaultLocale: 'pt-BR',
    locales: ['pt-BR'],
  },

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
          editUrl: 'https://github.com/GabrielFerreiraMendes/minusframework/edit/main/docs/',
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    image: 'img/logo.svg',
    colorMode: {
      respectPrefersColorScheme: true,
    },
    navbar: {
      title: 'MinusFrameWork',
      logo: {
        alt: 'MinusFrameWork Logo',
        src: 'img/logo.svg',
      },
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'docsSidebar',
          position: 'left',
          label: 'Documentação',
        },
        {to: '/pricing', label: 'Planos', position: 'left'},
        {to: '/about', label: 'Sobre', position: 'left'},
        {to: '/licensing', label: 'Licenciamento', position: 'left'},
        {
          href: 'https://github.com/GabrielFerreiraMendes/minusframework',
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      logo: {
        alt: 'MinusFrameWork',
        src: 'img/logo.svg',
        height: 32,
      },
      links: [
        {
          title: 'Docs',
          items: [
            {
              label: 'Guia Rápido',
              to: '/docs/getting-started',
            },
            {
              label: 'ORM',
              to: '/docs/orm/',
            },
            {
              label: 'CLI',
              to: '/docs/cli/',
            },
          ],
        },
        {
          title: 'Planos',
          items: [
            { label: 'Free', to: '/pricing' },
            { label: 'Pro', to: '/pricing' },
            { label: 'Enterprise', to: '/pricing' },
          ],
        },
        {
          title: 'Suporte',
          items: [
            {
              label: 'GitHub Issues',
              href: 'https://github.com/GabrielFerreiraMendes/minusframework/issues',
            },
            {
              label: 'E-mail',
              href: 'mailto:gabrielferreiramendes.dev@gmail.com',
            },
          ],
        },
      ],
      copyright: `
        <div style="display:flex;justify-content:center;gap:0.5rem;flex-wrap:wrap;margin-bottom:0.75rem">
          <img src="https://img.shields.io/badge/Delphi-11+-E2243D?logo=delphi&logoColor=white" alt="Delphi 11+">
          <img src="https://img.shields.io/badge/Win32%20|%20Win64-0078D4?logo=windows&logoColor=white" alt="Platform">
          <img src="https://img.shields.io/badge/Licença-MIT-brightgreen" alt="Licença">
        </div>
        &copy; ${new Date().getFullYear()} MinusFrameWork &middot; Free (MIT) &middot; Pro &middot; Enterprise
      `,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
