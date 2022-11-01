import React from 'react';
import PropTypes from 'prop-types';
import shortid from 'shortid';

import applyComponentDecorators from 'javascript_lib/utils/apply_component_decorators';

import Clickable from 'javascript_lib/components/clickable';

import tabsStyle from 'javascript_lib/styles/tabs.style';
import 'javascript_lib/styles/tabs.scss';


class Tabs extends React.Component {

  constructor(props) {
    super(props);

    this.state = {
      tabIndex: 0
    };
  }

  _handleTabClick(tabIndex) {
    this.setState({tabIndex});
  }

  _getCurrentTab() {
    return this.props.tabs[this.state.tabIndex];
  }

  _renderContentArea() {
    const currentTab = this._getCurrentTab();

    return(
      <div className="tabs__tab-content">
        { currentTab ? currentTab.content : null }
      </div>
    );
  }

  _renderTabHighlight() {
    return(
      <div className="tabs__highlight-container">
        <div
          className="tabs__highlight"
          style={tabsStyle.highlight(this.props.tabs.length, this.state.tabIndex)}
        ></div>
      </div>
    );
  }

  _renderTab(tab, index) {
    return(
      <div
        key={shortid.generate()}
        className="tabs__tab"
        onClick={() => this._handleTabClick(index)}
      >
        <Clickable
          clickableClassName={this.props.tabClassName ? "tabs__tab-clickable " + this.props.tabClassName : "tabs__tab-clickable" }
        >
          { tab.title }
        </Clickable>
      </div>
    );
  }

  _renderTabs() {
    return(
      <div className="tabs__tabs_container">
        {
          this.props.tabs.map((tab, index) => {
            return this._renderTab(tab, index);
          })
        }
      </div>
    );
  }

  render() {
    return(
      <div className="tabs">
        {this._renderTabs()}
        {this._renderTabHighlight()}
        {this._renderContentArea()}
      </div>
    );
  }
}

Tabs.propTypes = {
  tabs: PropTypes.array,
  tabClassName: PropTypes.string
};

Tabs.defaultProps = {
  children: null,
  tabClassName: null
};

export default applyComponentDecorators(Tabs);
