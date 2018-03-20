# `Html.Safe`

> This package is an _early_ exploration.
> You probably don't want to use it, other than to try it out.
> 
> If you do experiment with it, we are glad to hear feedback about it.
> This includes:
>
> * pain points
> * ways to break the package guarantees

This package aims to let you build views where certain things can't happen.
It does this by providing a `SafeHtml msg` type.
Unlike `Html`, `SafeHtml` cannot represent arbitrary DOM trees.

With `Html` third party code you call can inject arbitrary JS into your view.
Ideally, `SafeHtml` would protect you from that attack vector.
If it's possible to cover others too, that's even better!