import {
  BaseSource,
  Context,
  Item,
} from "https://deno.land/x/ddc_vim@v3.9.0/types.ts";
import { Denops, fn } from "https://deno.land/x/ddc_vim@v3.9.0/deps.ts";

type Params = Record<never, never>;

export class Source extends BaseSource<Params> {
  async gather(args: {
    denops: Denops;
    context: Context;
  }): Promise<Item[]> {
    const snippets = await args.denops.call(
      "neosnippet#helpers#get_completion_snippets",
    ) as Record<
      string,
      unknown
    >[];
    if (!snippets) {
      return [];
    }

    const wordMatch = /\w+$/.exec(args.context.input);
    const charsMatch = /\S+$/.exec(args.context.input);
    const isWord = wordMatch && charsMatch && wordMatch[0] == charsMatch[0];

    const ret: Record<string, Item> = {} as Record<string, Item>;
    for (const key in snippets) {
      const val = snippets[key];

      const options = val.options as Record<string, Item>;
      if (
        (!options.head || /^\s*\S+$/.test(args.context.input)) &&
        (!options.word || isWord) &&
        (!val.regexp ||
          await fn.matchstr(args.denops, args.context.input, val.regexp) != "")
      ) {
        const word = val.word as string;
        if (!(word in ret)) {
          ret[word] = { word, menu: val.menu_abbr as string, };
        }
      }
    }
    return Object.values(ret);
  }

  params(): Params { return {}; }
}
