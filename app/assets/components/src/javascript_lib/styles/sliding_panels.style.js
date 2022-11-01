export default {
  panelsContainer: (numberOfPanels, currentPanelIndex) => {
    return {
      left: -currentPanelIndex * 100 + "%",
      width: numberOfPanels * 100 + "%"
    };
  },
  panel: (numberOfPanels) => {
    return {
      width: 100 / numberOfPanels + "%"
    };
  }
};
