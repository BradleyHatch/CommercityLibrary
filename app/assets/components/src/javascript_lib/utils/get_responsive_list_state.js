import { getDeviceDimensions } from 'javascript_lib/utils/media_break_point_utils';


export default function getResponsiveListState(originalListItems, breakPoints, showMore, byColumnsAndRows=false) {
  const breakPoint = getAppropriateBreakPoint(breakPoints);

  return {
    listItems: getListItems(originalListItems, breakPoint, showMore, byColumnsAndRows),
    listItemStyle: getListItemStyle(breakPoint),
    showMore
  };
}

 export function getListItems(listItems, breakPoint, showMore, byColumnsAndRows) {
  const numberOfItemsToShow = byColumnsAndRows ? breakPoint.rows * breakPoint.columns : breakPoint.items;

  if(showMore) {
    return listItems.slice(0).concat({showMoreToggle: true});
  }
  if(numberOfItemsToShow >= listItems.length) {
    return listItems;
  }

  return listItems.slice(0, numberOfItemsToShow).concat({showMoreToggle: true});
}

export function getAppropriateBreakPoint(breakPoints) {
  return breakPoints.reduce((previous, current) => {
    return current.width > getDeviceDimensions().width && current.width < previous.width ? current : previous;
  });
}

export function getListItemStyle(breakPoint) {
  return {
    width: (100/breakPoint.columns).toFixed(2) + "%",
    display: "inline-block"
  };
}
