import { buildHealListHandler } from '../../../../lib/heal-list';
export const GET = buildHealListHandler({
  table: 'heal_meditations',
  defaultSort: 'sort_order ASC, day_of_year ASC',
  searchableFields: ['title', 'body', 'reflection', 'scripture_text'],
  filterableFields: ['is_published', 'is_sleep_story', 'theme', 'season', 'day_of_year', 'slug'],
});
