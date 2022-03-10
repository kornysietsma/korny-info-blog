---

title: Better D3 sites with react
date: 2020-07-19 18:41 GMT
tags: tech

---

## Disclaimers

I'm not a React nor a D3 expert.  I'm too much of a generalist these days to consider myself an expert in anything really!  I am happy to be told how to correct or improve any of these examples, and of course don't just copy me - take what is useful from my stuff, and build your own, better things!

Also note I built my sample code using `create-react-app` - and I haven't cleaned out all the files that creates, so there might be some junk hanging around.

TL;DR: my sample code is at <https://github.com/kornysietsma/d3-react-demo>

## The ancient past - tinkering

I've been playing with D3 for quite a while now - I tinkered with D3 on a clojure server [in 2013](https://github.com/kornysietsma/d3spike) and [in 2018](https://github.com/kornysietsma/d3-modern-demo) I shared an approach that mostly worked for me - using modern JavaScript and CSS, ditching JQuery or other frameworks, and going serverless, because in most cases having a purely static site worked for me, and made it much easier to host and share visualisations.

However it was always painful to build the non-SVG parts of my visualisations.  Forms, inputs, sliders, and the like, are a hassle to build yourself once you get any complexity at all.

What I needed was to integrate with a more modern JavaScript framework - in 2019 I finally found time to learn some React, and I decided it'd be good to combine the two.

## The recent past - adding React

Unfortunately, it's not that straightforward to do so.  Basically React likes to control the DOM - tracking state changes, diffing a virtual DOM with the real DOM, and the like.  D3 also likes to control the DOM - and you need to work out how to stop them fighting.

There are several approaches that can be used here - there's a nice overview in ["Bringing Together React, D3, And Their Ecosystem" by Marcos Iglesias](https://www.smashingmagazine.com/2018/02/react-d3-ecosystem/) - basically there's a spectrum from letting React and D3 largely own their own parts of the DOM, through to letting React look after all the DOM and just using D3 to do D3 special bits.  I was more keen on letting them be largely isolated - D3 is very good at what it does, and the less react-y it is, the more you can reuse some of the millions of great D3 examples that are out there.

I also found this great article: ["React + D3 - the Macaroni and Cheese of the Data Visualization World" by Leigh Steiner](https://towardsdatascience.com/react-d3-the-macaroni-and-cheese-of-the-data-visualization-world-12bafde1f922) which was extremely helpful, and the basis of most of my approach.

However, it didn't go into all that much detail - and also, despite mentioning the newer React functional style and hooks, most of it was based on old `componentDidUpdate` logic.  And state handling seemed tricky.

Also, another big thing for me, is it didn't explain how to work with [the D3 join model](https://bost.ocks.org/mike/join/) (D3 examples often don't, sadly).  The idea is, done properly, D3 rendering can detect changed in a diagram's underlying data, and cleanly handle adding new elements, updating changed elements, and deleting removed elements - with transitions if you want.  [D3 recently added a cool `join` function](https://github.com/d3/d3-selection#joining-data) which makes this even easier.

So I started tinkering with making this work my way...

## The present - React + D3 with hooks

My current approach is at <https://github.com/kornysietsma/d3-react-demo> - to be precise, this article is based on code [at this commit](https://github.com/kornysietsma/d3-react-demo/tree/d0c64f59351f8d1e73053ae57cc1c2e8569dc7af) in case the repo has moved on by the time you read this.

### The D3 parts

D3 only exists in the [Viz.js](https://github.com/kornysietsma/d3-react-demo/blob/bdeb31c93a27a958bf4864b6ffedc9ef6157f10f/src/Viz.js) file - everything else is React.  The `Viz` component creates a single `svg` element:

~~~html
    <aside className="Viz">
      <svg className="chart" ref={d3Container} />
    </aside>
~~~

That `ref={d3Container}` means React creates a reference to this DOM element for manipulation by the `Viz` component - see [Refs and the DOM](https://reactjs.org/docs/refs-and-the-dom.html) in the react docs for more.

The heart of the `Viz` component uses `useEffect()` as mentioned in the Macaroni and Cheese article, to trigger changes to the D3 component as a side-effect - if and only if the data being referenced has changed.  The core of the `Viz` update logic is this code:

~~~jsx
const Viz = (props) => {
  const d3Container = useRef(null);
  const { dataRef, state, dispatch } = props;

  const prevState = usePrevious(state);

  useEffect(() => {
      // d3 update logic hidden
  }, [dataRef, state, dispatch, prevState]);
    return (
    <aside className="Viz">
      <svg className="chart" ref={d3Container} />
    </aside>
  );
};
~~~

UseEffect takes four properties - and will only be called if any of these has changed:

- `dataRef` is another ref - in this case to the raw data to be visualised.  More on that later.  As it's a reference (think pointer) it doesn't actually change, it's included here to avoid React complaining
- `state` is where I put _all_ the visualisation state - what to show, what colours to use, interactions etc.  Generally it's the only thing that might change
- `dispatch` is a global dispatch function that D3 can use to make changes to the state - more on that later.  Again, it shouldn't change, so it's just here to keep d3 happy.
- `prevState` is the _previous state_ - this is a trick I got from [this Stack Overflow question](https://stackoverflow.com/questions/53446020/how-to-compare-oldvalues-and-newvalues-on-react-hooks-useeffect) - it stores the value of `state` from last time `Viz` was shown, allowing me to detect what has really changed.

### Initial setup, cheap changes, and expensive changes

One thing I wanted to handle was to separate out different kinds of visualisation updates.  For simple things this is complete overkill - but I often find that my UI changes fall into two categories:

- Cheap changes that really just need to update some colours or highlights, really quickly
- Expensive changes that need more serious processing, possibly with some delay

For example, dragging a colour slider to change colours might be so cheap you want it to happen on every mouse drag.  But changing a date selector might mean re-processing the underlying data for some reason, and that might be slow.

There are also the things you do once and only once - adding `svg` groups, for example.

So the code looks at the `state`, and the `previousState`, and works out what has changed:

~~~js
    if (prevState === undefined) {
      initialize();
    } else if (!_.isEqual(prevState.expensiveConfig,
                          state.expensiveConfig)) {
      draw();
    } else if (!_.isEqual(prevState.config,
                          state.config)) {
      redraw();
    } else {
        // nothing to do
    }
~~~

I'm using [lodash](https://lodash.com/) to do object comparison - `state` can be deeply nested, and JavaScript doesn't have a reliable way to do deep object comparison.

I won't go much into the `initialize`, `draw` and `redraw` functions at this stage - they are relatively straightforward.  I don't even actually use the cheap/expensive code in the demo - `draw` just calls `redraw`.

The only interesting thing to note is how to interact with the world outside D3 - using the `dispatch` function:

~~~js
  .on("click", (node, i, nodeList) => {
    dispatch({ type: "selectData", payload: node.id });
~~~

How this works will be covered later.

### Loading the data

The data for my demo is in a JSON file - you could just `import` it, but that'd load it synchronously - fine for small amounts of data, but for larger datasets I want to be able to warn the user that data is loading.

So instead of the default `App` component, I have a `Loader`, which again uses `useEffect` to load the initial data as a side-effect of rendering:

~~~jsx
const Loader = () => {
  const url = `${process.env.PUBLIC_URL}/data.json`;

  const dataRef = useRef(null);

  const data = useFetch(url);
  dataRef.current = data;

  return data == null ? <div>Loading...</div> : <App dataRef={dataRef} />;
};
~~~

`useFetch` is a function that makes a [fetch](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API/Using_Fetch) call (the modern alternative to `XMLHttpRequest`) to get the raw JSON data, and apply any needed postprocessing.

This again uses `useEffect` - see [the react docs on this](https://reactjs.org/docs/hooks-effect.html) for more background.  Effectively, the first time the `Loader` component is rendered, it will call `useFetch` which actually returns have no `data` so will show `<div>Loading...</div>` - and kick off `useFetch` which returns a `null` response.

`useFetch` looks like this:

~~~js
const useFetch = (url) => {
  const [data, setData] = useState(null);

  useEffect(() => {
    async function fetchData() {
      const response = await fetch(url);
      const json = await response.json();
      // postprocessing removed for clarity
      setData(/* stuff */);
    }
    fetchData();
  }, [url]);

  return data;
};
~~~

In this code, `useEffect` takes a parameter `[url]` - this means it will only be run if the URL has changed (which should never happen in this example) so it runs once.  When it has fetched the data, it calls `setData` which sets the `data` state - which triggers a re-render of the `Loader` (see [the react docs for useState](https://reactjs.org/docs/hooks-reference.html#usestate)).

The second time `Loader` is rendered, the call to `useFetch` effectively does nothing, as the value of `[url]` has not changed. (If it changed it could get into a loop, which would be bad).  But it will return the updated `data` value, which I put into yet another `ref`: `dataRef` and pass to the `App`:

~~~html
<App dataRef={dataRef} />
~~~

I'm using a ref here so the `App` doesn't need to check the whole `data` object to see if it should be re-rendered.  (This may be unnecessary - I'm not clear enough about react internals to be sure what would happen if I just passed `data` around - it may have no real overhead?)

### Showing the App

`App` is fairly straightforward, with a bit of magic to set up the state and dispatch mechanisms:

~~~jsx
const App = props => {
  const { dataRef } = props;

  const [vizState, dispatch] = useReducer(
    globalDispatchReducer,
    dataRef,
    initialiseGlobalState
  );

  return (
    <div className="App">
      <header className="App-header">
        <h1>Korny&apos;s D3 React Demo</h1>
      </header>
      <Viz dataRef={dataRef} state={vizState} dispatch={dispatch} />
      <Controller dataRef={dataRef} state={vizState} dispatch={dispatch} />
      <Inspector dataRef={dataRef} state={vizState} dispatch={dispatch} />
    </div>
  );
};
~~~

The UI is basically three components, `Viz` which is the D3 visualisation, `Controller` for the user controls on the left panel, `Inspector` to inspect a particular data point.  They all take the same parameters - `dataRef` for the raw data, `state` for the current state, and `dispatch` for updating the state.

### State and Dispatching

State management is done through `useReducer` - see [the react docs](https://reactjs.org/docs/hooks-reference.html#usereducer) for more.  Basically it takes three parameters:

- the reducer function, `globalDispatchReducer`
- the initial data, `dataRef`
- an initialising function `initialiseGlobalState` - this allows for lazy calculation of the initial state.

The initialise function creates the initial state object - it has a shape roughly like this:

~~~js
  {
    config: {
        // cheap state
    },
    expensiveConfig: {
        // expensive state
    },
    constants: {
        // state that never changes
    }
  }
~~~

As discussed earlier, I split the state into cheap and expensive, and rendering is different depending on what changes.  There is also a `constants` section - this doesn't really need to be in the state, but it's useful, especially as sometimes something starts off as constant (like margins, in this example) but later might become modifiable, at which time you can move it somewhere else in the state.

The `globalDispatchReducer` is what gets called whenever anything calls `dispatch()` - earlier there was an example of an `onClick` handler which called `dispatch({ type: "selectData", payload: node.id })` - the `Controller` also calls `dispatch` whenever a user clicks a control.

`globalDispatchReducer` is basically a large `switch` statement:

~~~js
function globalDispatchReducer(state, action) {
  switch (action.type) {
    case "selectData": {
      const result = _.cloneDeep(state);
      result.config.selected = action.payload;
      return result;
    }
    // rest removed for clarity
~~~

It takes the current `state` and an `action` - which is `{ type: "selectData", payload: node.id }` in the example above.  Whatever it returns is set as the new state, which will trigger re-rendering of any affected react components.

I'm using [lodash](https://lodash.com/) to clone the state here - alternatively you can just use es6 destructuring assignment, such as:

~~~js
      return {
        ...state,
        config: { ...config, selected: action.payload }
      };
~~~

However this gets hairy for deeply nested structures, as the returned object is _not_ a deep clone of the original object - in the above example, `state.expensiveConfig.dateRange` would be a shared reference between the original state and the new state, rather than an actual new object.  That might be OK, but it can be quite counterintuitive - it's caught me out before, so I like to use `cloneDeep` and be explicit.  (It'd be nice to rework this with `immutable.js` but that's a rabbit hole I don't have time for now)

### The overall event flow

The above might be a bit confusing - in a nutshell, I pass a `dispatch` function to every component, including d3 renderers.

When something calls `dispatch`:

1. `globalDispatchReducer` is called, returning a new state
2. React updates the `vizState` state owned by the `App` component, so re-renders `App`
3. `App` in turn re-renders everything else.
4. Normal components are updated in standard React fashion, using virtual DOM magic so not too much gets re-rendered
5. the `Viz` component looks at the updated `state` and redraws whichever bits of the D3 visualisation need to be redrawn.

All of this is surprisingly smooth - I've had pages with thousands of `svg` nodes which updated nicely as I drag a control slider.  I initially thought I'd need to find ways to bypass react for some UI updates, but so far I haven't.

## The future

I'm using this for my polyglot code tools - I intend to write more about those when I have the time.

I'd really value feedback on this post - especially as I'm not a react expert, and there are probably major things I've missed!  Feedback via Disqus below, or via `@kornys` on Twitter.

## Update Mar 2022

I have tweaked the repo a bit - using Typescript now, and updated versions of React, D3, eslint and prettier.  Haven't really had time to update this blog post, but hopefully it's mostly still relevant.
