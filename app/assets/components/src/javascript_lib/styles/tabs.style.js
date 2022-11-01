
export default {
  highlight: (tabsSize, currentIndex) => {
    const width = 100 / tabsSize;
    const left = width * currentIndex;

    return  {
        width: width + "%",
        left: left + "%"
    };
  }
}
