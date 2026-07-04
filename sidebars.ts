import type {SidebarsConfig} from '@docusaurus/plugin-content-docs';

const sidebars: SidebarsConfig = {
  docsSidebar: [
    {
      type: 'category',
      label: 'Começar',
      items: ['getting-started'],
    },
    {
      type: 'category',
      label: '📦 Free (MIT)',
      items: [
        'orm/index',
        'migrator/index',
        'cli/index',
      ],
    },
    {
      type: 'category',
      label: '⭐ Pro',
      items: [
        'messaging/index',
        'extensions/index',
        'modules/FeatureFlags/index',
      ],
    },
    {
      type: 'category',
      label: '🔒 Enterprise',
      items: [
        'telemetry/index',
        'ai/index',
      ],
    },
    {
      type: 'category',
      label: 'Sobre',
      items: ['about', 'licensing'],
    },
  ],
};

export default sidebars;
