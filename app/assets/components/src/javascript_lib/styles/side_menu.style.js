import Styles from 'javascript_lib/services/style_service';

function getDimensions(anchorSide, size) {
  switch(anchorSide) {
    case "top":
    case "bottom":
      return { height: size + "px", width: "100%" };
    default:
      return { width: size + "px", height: "100%"};
  }
}

function getPosition(anchorSide, size, open) {
  return open ? { [anchorSide]: "0px" } : { [anchorSide]: - size + "px" };
}

function getSpacerDimensions(anchorSide, size, open) {
  const dimensionSize = open ? size : 0;

  return getDimensions(anchorSide, dimensionSize);
}


export default {
  sideMenu: (zIndex) => {
    return  {
      zIndex
    };
  },
  sideMenuOverlay: (anchorSide, size, open, customSize) => {
    return Styles.merge(getDimensions(anchorSide, size), getPosition(anchorSide, size, open), customSize);
  },
  sideMenuSpacer: (anchorSide, size, open) => {
    return getSpacerDimensions(anchorSide, size, open);
  }
}
