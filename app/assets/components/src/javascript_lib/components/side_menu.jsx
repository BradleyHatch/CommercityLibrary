import React from 'react';
import PropTypes from 'prop-types';

import applyComponentDecorators from 'javascript_lib/utils/apply_component_decorators';

import sideMenuStyle from 'javascript_lib/styles/side_menu.style';

import 'javascript_lib/styles/side_menu.scss';


class SideMenu extends React.Component {

  constructor(props) {
    super(props);
  }

  _getCalculatedSize() {
    return this.props.size * (this.props.responsivePercentage / 100);
  }

  _renderSpacer() {
    return(
      <div
        className="side-menu__spacer"
        style={sideMenuStyle.sideMenuSpacer(
          this.props.anchorSide,
          this._getCalculatedSize(),
          this.props.open
        )}
      ></div>
    );
  }

  render() {
    return(
      <div
        className={ this.props.sideMenuClassName ? "side-menu " + this.props.sideMenuClassName : "side-menu" }
        style={sideMenuStyle.sideMenu(this.props.zIndex)}
      >
        <div
          className="side-menu__overlay"
          style={sideMenuStyle.sideMenuOverlay(
            this.props.anchorSide,
            this._getCalculatedSize(),
            this.props.open,
            this.props.customSize)}
        >
          <div className="side-menu__overlay-inner" style={sideMenuStyle.sideMenuInner}>
            {this.props.children}
          </div>
        </div>
        {this.props.floatOver ? null : this._renderSpacer()}
      </div>
    );
  }
}

SideMenu.propTypes = {
  responsivePercentage: PropTypes.number,
  children: PropTypes.node,
  size: PropTypes.number,
  open: PropTypes.bool,
  anchorSide: PropTypes.string,
  floatOver: PropTypes.bool,
  zIndex: PropTypes.number,
  customSize: PropTypes.object,
  sideMenuClassName: PropTypes.string
};

SideMenu.defaultProps = {
  responsivePercentage: 100,
  children: null,
  size: 100,
  open: false,
  anchor: "left",
  floatOver: false,
  zIndex: 5000,
  customSize: {},
  sideMenuClassName: null
};

export default applyComponentDecorators(SideMenu);
