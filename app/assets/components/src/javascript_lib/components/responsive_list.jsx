import React from 'react';
import PropTypes from 'prop-types';
import shortid from 'shortid';
import window from 'window-or-global';

import applyComponentDecorators from 'javascript_lib/utils/apply_component_decorators';
import getResponsiveListState from 'javascript_lib/utils/get_responsive_list_state';


class ResponsiveList extends React.Component {

  constructor(props) {
    super(props);

    this.state = this._getListState();
  }

  _getListState(showMore=false) {
    return getResponsiveListState(this.props.listItems, this.props.breakPoints, showMore, this.props.byColumnsAndRows);
  }

  _setListState(showMore) {
    this.setState(this._getListState(showMore));
  }

  componentDidMount() {
    window.addEventListener("resize", () => this._setListState(this.state.showMore));
  }

  componentWillUnmount() {
    window.removeEventListener("resize");
  }

  _toggleShowMore() {
    this._setListState(!this.state.showMore);
  }

  _getListItemStyle() {
    return this.props.byColumnsAndRows ? this.state.listItemStyle : {};
  }

  _renderToggle() {
    const toggleText = this.state.showMore ? "show less" : "show more";

    return (
      <div
        key={shortid.generate()}
        style={this._getListItemStyle()}
        className={this.props.listItemClassName}
      >
        <span onClick={this._toggleShowMore}>{toggleText}</span>
      </div>
    );
  }

  _renderListItem(listItem) {
    if(listItem.showMoreToggle) {
      return this._renderToggle();
    } else {
      return(
        <div
          key={shortid.generate()}
          style={this._getListItemStyle()}
          className={this.props.listItemClassName}
          dangerouslySetInnerHTML={{__html: listItem}}
        />
      );
    }
  }

  render() {
    return(
      <div>
        {this.state.listItems.map(listItem => this._renderListItem(listItem))}
      </div>
    );
  }
}

ResponsiveList.propTypes = {
  listItems: PropTypes.array,
  breakPoints: PropTypes.array,
  listItemClassName: PropTypes.string,
  byColumnsAndRows: PropTypes.bool
};

ResponsiveList.defaultProps = {
  listItems: [],
  breakPoints: [],
  listItemClassName: null,
  byColumnsAndRows: false
};

export default applyComponentDecorators(ResponsiveList);
