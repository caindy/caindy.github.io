
View - abstracts UI, humbly
+ getState :: unit    -> UXModel // vdom read
+ setState :: UXModel -> unit    // vdom update

- render   :: UXModel -> unit    // DOM update
- updated  :: unit    -> UXModel // event

Presenter - coordinates views
+ Diff  :: PresentationModel -> (unit -> UXModel) -> Patch
+ Apply :: Patch             -> (UXModel -> unit) -> PresentationModel
+ State :: get,set PresentationModel

Application
+ Interpret :: Patch  -> AppModel -> Intent
+ Query     :: Intent -> AppModel -> Patch

UXModel - a state-bag
PresentationModel - ViewModel
AppModel - "the graph"

Where do the functions run?

What determines the shape of the data?


State        :: 'm with get, set
Render       :: 'm -> ()
UpdatedEvent :: ('m -> ()) -> ()
Diff         :: 'm -> 'n -> 'p
Apply        :: 

