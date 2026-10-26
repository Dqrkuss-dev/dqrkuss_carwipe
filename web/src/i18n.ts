type Dictionary = Record<string, string>;
export type TextArgs = Record<string, string | number>;
export type T = (key: string, args?: TextArgs) => string;

const dictionaries: Record<string, Dictionary> = {};

export function registerDictionaries(list: Record<string, Dictionary>) {
  Object.assign(dictionaries, list);
}

// Text in `locale`, else English, else the key itself. {name} is replaced by args.name.
export function translator(locale: string): T {
  return (key, args = {}) => {
    const template = dictionaries[locale]?.[key] ?? dictionaries.en?.[key];
    if (template === undefined) return key;
    return template.replace(/\{(\w+)\}/g, (match, name: string) => String(args[name] ?? match));
  };
}
