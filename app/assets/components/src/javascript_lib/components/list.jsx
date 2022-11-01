import React from 'react';
import PropTypes from 'prop-types';
import shortid from 'shortid';

import applyComponentDecorators from 'javascript_lib/utils/apply_component_decorators';

import 'javascript_lib/styles/list.scss';


class List extends React.Component {

  constructor(props) {
    super(props);
  }

  _renderListItem(item) {
    const renderedItem = this.props.customItemRender ? this.props.customItemRender(item) : item;

    if(renderedItem) {
      return(
        <div key={shortid.generate()} className="list__item">
          {renderedItem}
        </div>
      );
    }

    return null;

  }

  render() {
    return(
      <div className="list">
        {
          this.props.listItems.map(item => {
            return this._renderListItem(item);
          })
        }
      </div>
    );
  }
}

List.propTypes = {
  listItems: PropTypes.array,
  customItemRender: PropTypes.func
};

List.defaultProps = {
  listItems: [],
  customItemRender: null
};

export default applyComponentDecorators(List);
